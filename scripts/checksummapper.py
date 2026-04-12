import argparse
import ctypes
import json
import os
import subprocess
import sys
import threading
import time
import zlib
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from datetime import datetime
from io import BufferedReader
from pathlib import Path
from pprint import pprint
from typing import Generator, Sequence, TypedDict

if sys.platform == "win32":
    from ctypes import wintypes

try:
    import curses

    HAS_CURSES = True
except ImportError:
    HAS_CURSES = False

NUMBER_OF_THREADS = 1
IS_WINDOWS = sys.platform == "win32"
IS_MACOS = sys.platform == "darwin"

if IS_WINDOWS:
    FO_DELETE = 3
    FOF_ALLOWUNDO = 0x0040
    FOF_NOCONFIRMATION = 0x0010
    FOF_NOERRORUI = 0x0400
    FOF_SILENT = 0x0004

    class SHFILEOPSTRUCTW(ctypes.Structure):
        _fields_ = [
            ("hwnd", wintypes.HWND),
            ("wFunc", wintypes.UINT),
            ("pFrom", wintypes.LPCWSTR),
            ("pTo", wintypes.LPCWSTR),
            ("fFlags", ctypes.c_ushort),
            ("fAnyOperationsAborted", wintypes.BOOL),
            ("hNameMappings", wintypes.LPVOID),
            ("lpszProgressTitle", wintypes.LPCWSTR),
        ]


@dataclass
class FileInfo:
    name: str
    size: int
    path: Path
    checksum: int | None = None


class Entry(TypedDict):
    checksum: int
    entries: list[FileInfo]


class ChecksumMapper:
    def __init__(self, verbose: bool = True) -> None:
        self.checksum_map: dict[int, Entry] = {}
        self.verbose = verbose

    def add(self, file_info: FileInfo) -> None:
        if file_info.checksum is None:
            with file_info.path.open("rb") as fd:
                file_info.checksum = crc32(fd)

        if file_info.checksum not in self.checksum_map:
            self.checksum_map[file_info.checksum] = {
                "checksum": file_info.checksum,
                "entries": [],
            }
        if self.verbose:
            print(f"Processed {file_info.path}: {file_info.checksum}")
        self.checksum_map[file_info.checksum]["entries"].append(file_info)

    def get(self, checksum: int) -> list[FileInfo] | None:
        entry = self.checksum_map.get(checksum, None)
        if entry is not None:
            return entry["entries"]
        return None

    def save(self, path: Path, indent: int | None = None) -> None:
        with path.open("w") as fd:
            json.dump(
                self.checksum_map, fd, default=_json_default, indent=indent
            )

    def load(self, path: Path) -> None:
        with path.open("r") as fd:
            raw = json.load(fd)
        self.checksum_map = {}
        for key, entry in raw.items():
            try:
                cs = int(key)
            except (ValueError, TypeError):
                cs = key
            entries = []
            for item in entry.get("entries", []):
                fi = _parse_file_info(item)
                if fi is not None:
                    entries.append(fi)
            self.checksum_map[cs] = {"checksum": cs, "entries": entries}

    def print(self) -> None:
        pprint(self.checksum_map)

    def get_duplicates(self) -> dict[int, list[FileInfo]]:
        return {
            checksum: entry["entries"]
            for checksum, entry in self.checksum_map.items()
            if len(entry["entries"]) > 1
        }

    def compare(self, other: "ChecksumMapper") -> dict[int, FileInfo]:
        """Compare this ChecksumMapper with another and return a dict of
        checksums that are present in both."""
        common_checksums = set(self.checksum_map.keys()) & set(
            other.checksum_map.keys()
        )
        common = {
            checksum: self.checksum_map[checksum]["entries"]
            for checksum in common_checksums
        }

        for checksum in common_checksums:
            common[checksum] = (
                self.checksum_map[checksum]["entries"]
                + other.checksum_map[checksum]["entries"]
            )

        return common

    def remove_file(self, path: Path) -> bool:
        removed = False
        for checksum in list(self.checksum_map):
            entries = self.checksum_map[checksum]["entries"]
            kept_entries = [entry for entry in entries if entry.path != path]
            if len(kept_entries) != len(entries):
                removed = True
            if kept_entries:
                self.checksum_map[checksum]["entries"] = kept_entries
            else:
                del self.checksum_map[checksum]
        return removed

    def prune_missing_files(self) -> int:
        removed_count = 0
        for checksum in list(self.checksum_map):
            entries = self.checksum_map[checksum]["entries"]
            kept_entries = [entry for entry in entries if entry.path.exists()]
            removed_count += len(entries) - len(kept_entries)
            if kept_entries:
                self.checksum_map[checksum]["entries"] = kept_entries
            else:
                del self.checksum_map[checksum]
        return removed_count

    def refresh_reported_duplicates(self) -> tuple[int, int, int]:
        duplicate_paths = {
            entry.path
            for entries in self.get_duplicates().values()
            for entry in entries
        }
        refreshed_count = 0
        missing_count = 0
        error_count = 0

        for path in duplicate_paths:
            self.remove_file(path)

        for path in sorted(duplicate_paths):
            try:
                stat_result = path.stat()
            except FileNotFoundError:
                missing_count += 1
                continue
            except OSError:
                error_count += 1
                continue

            try:
                self.add(
                    FileInfo(
                        name=path.name,
                        size=stat_result.st_size,
                        path=path,
                    )
                )
                refreshed_count += 1
            except OSError:
                error_count += 1

        return refreshed_count, missing_count, error_count


def crc32(fd: BufferedReader) -> int:
    """Calculate the CRC32 checksum of a file-like object."""
    checksum = 0
    while True:
        chunk = fd.read(8192)
        if not chunk:
            break
        checksum = zlib.crc32(chunk, checksum)
    return checksum & 0xFFFFFFFF


def traverse(path: Path) -> Generator[FileInfo, None, None]:
    for path in path.rglob("*"):
        if path.is_file():
            yield FileInfo(name=path.name, size=path.stat().st_size, path=path)


def _json_default(obj: object) -> object:
    """JSON serializer for non-standard types."""
    if isinstance(obj, FileInfo):
        return {
            "name": obj.name,
            "size": obj.size,
            "path": str(obj.path),
            "checksum": obj.checksum,
        }
    if isinstance(obj, Path):
        return str(obj)
    return str(obj)


def _parse_file_info(raw: object) -> FileInfo | None:
    """Reconstruct a FileInfo from JSON-loaded data."""
    if isinstance(raw, dict):
        try:
            return FileInfo(
                name=raw.get("name", ""),
                size=raw.get("size", 0),
                path=Path(raw["path"]),
                checksum=raw.get("checksum"),
            )
        except (KeyError, TypeError):
            return None
    return None


##################################### CLI #####################################


def map_handler(args: argparse.Namespace) -> None:
    path = Path(args.directory)
    mapper = ChecksumMapper()

    start = time.time()
    with ThreadPoolExecutor(max_workers=args.threads) as executor:
        futures = {
            executor.submit(mapper.add, file_info): file_info
            for file_info in traverse(path)
        }

        for future in as_completed(futures):
            file_info = futures[future]
            try:
                future.result()
            except Exception as exc:
                print(f"Error processing {file_info.path}: {exc}")

    mapper.save(Path.cwd() / f"checksum_map_{int(time.time())}.json")
    pprint(mapper.get_duplicates())

    end = time.time()
    print(f"Time taken: {end - start:.2f} seconds")


def compare_handler(args: argparse.Namespace) -> None:
    mapper1 = ChecksumMapper()
    mapper2 = ChecksumMapper()

    mapper1.load(Path(args.map1))
    mapper2.load(Path(args.map2))

    common = mapper1.compare(mapper2)
    pprint(common)


def report_handler(args: argparse.Namespace) -> None:
    mapper = ChecksumMapper()
    mapper.load(Path(args.map))

    duplicates = mapper.get_duplicates()
    pprint(duplicates)


##################################### TUI #####################################


class TuiApp:
    """Interactive curses-based TUI for ChecksumMapper."""

    COLOR_HEADER = 1
    COLOR_OK = 2
    COLOR_GROUP = 3
    COLOR_WARN = 4
    COLOR_BAR = 5
    COLOR_SELECT = 6

    def __init__(self, stdscr: "curses.window") -> None:
        self.stdscr = stdscr
        self.status_msg = ""
        self.running = True

        curses.start_color()
        curses.use_default_colors()
        curses.init_pair(self.COLOR_HEADER, curses.COLOR_CYAN, -1)
        curses.init_pair(self.COLOR_OK, curses.COLOR_GREEN, -1)
        curses.init_pair(self.COLOR_GROUP, curses.COLOR_YELLOW, -1)
        curses.init_pair(self.COLOR_WARN, curses.COLOR_RED, -1)
        curses.init_pair(self.COLOR_BAR, curses.COLOR_WHITE, curses.COLOR_BLUE)
        curses.init_pair(
            self.COLOR_SELECT, curses.COLOR_BLACK, curses.COLOR_WHITE
        )
        curses.curs_set(0)
        self.stdscr.keypad(True)

    # ── key helpers ─────────────────────────────────────────────────

    @staticmethod
    def _key_up(key: int) -> bool:
        return key in (curses.KEY_UP, ord("k"))

    @staticmethod
    def _key_down(key: int) -> bool:
        return key in (curses.KEY_DOWN, ord("j"))

    @staticmethod
    def _key_left(key: int) -> bool:
        return key in (curses.KEY_LEFT, ord("h"))

    @staticmethod
    def _key_right(key: int) -> bool:
        return key in (curses.KEY_RIGHT, ord("l"))

    @staticmethod
    def _key_enter(key: int) -> bool:
        return key in (curses.KEY_ENTER, 10, 13)

    @staticmethod
    def _key_quit(key: int) -> bool:
        return key == ord("q")

    @staticmethod
    def _key_backspace(key: int) -> bool:
        # Windows terminals can emit 8 for Backspace.
        return key in (curses.KEY_BACKSPACE, 127, 8)

    # ── drawing helpers ─────────────────────────────────────────────

    def _safe_addnstr(
        self, y: int, x: int, text: str, maxlen: int, attr: int = 0
    ) -> None:
        try:
            self.stdscr.addnstr(y, x, text, maxlen, attr)
        except curses.error:
            pass

    @staticmethod
    def _format_size(size: int | float) -> str:
        for unit in ("B", "KB", "MB", "GB", "TB"):
            if abs(size) < 1024:
                return f"{size:.1f} {unit}" if unit != "B" else f"{size} B"
            size /= 1024
        return f"{size:.1f} PB"

    @staticmethod
    def _format_checksum(cs: int | str) -> str:
        try:
            return f"0x{int(cs):08X}"
        except (ValueError, TypeError):
            return str(cs)

    def _draw_footer(self, text: str) -> None:
        h, w = self.stdscr.getmaxyx()
        self._safe_addnstr(
            h - 1, 0, text.center(w), w - 1, curses.color_pair(self.COLOR_BAR)
        )

    def _draw_status(self) -> None:
        if not self.status_msg:
            return
        h, w = self.stdscr.getmaxyx()
        self._safe_addnstr(
            h - 2,
            0,
            f" {self.status_msg}".ljust(w),
            w - 1,
            curses.color_pair(self.COLOR_GROUP),
        )
        self.status_msg = ""

    # ── text input ──────────────────────────────────────────────────

    def _text_input(self, prompt: str, prefill: str = "") -> str | None:
        """Prompt for a single line of text.  Returns None on Esc."""
        curses.curs_set(1)
        text = prefill
        cursor = len(text)

        while True:
            self.stdscr.clear()
            h, w = self.stdscr.getmaxyx()
            self._safe_addnstr(
                1,
                2,
                prompt,
                w - 4,
                curses.color_pair(self.COLOR_HEADER) | curses.A_BOLD,
            )

            max_vis = w - 4
            vis_start = max(0, cursor - max_vis + 1)
            self._safe_addnstr(
                3, 2, text[vis_start : vis_start + max_vis], max_vis
            )

            self._safe_addnstr(
                5,
                2,
                "Enter: Confirm  Esc: Cancel  Tab: Autocomplete",
                w - 4,
                curses.A_DIM,
            )
            self._draw_footer("Type a path and press Enter")

            try:
                self.stdscr.move(3, 2 + cursor - vis_start)
            except curses.error:
                pass
            self.stdscr.refresh()

            key = self.stdscr.getch()
            if key == 27:  # Esc
                curses.curs_set(0)
                return None
            elif self._key_enter(key):
                curses.curs_set(0)
                return text
            elif self._key_backspace(key):
                if cursor > 0:
                    text = text[: cursor - 1] + text[cursor:]
                    cursor -= 1
            elif key == curses.KEY_DC:
                if cursor < len(text):
                    text = text[:cursor] + text[cursor + 1 :]
            elif key == curses.KEY_LEFT:
                cursor = max(0, cursor - 1)
            elif key == curses.KEY_RIGHT:
                cursor = min(len(text), cursor + 1)
            elif key == curses.KEY_HOME:
                cursor = 0
            elif key == curses.KEY_END:
                cursor = len(text)
            elif key == 9:  # Tab – autocomplete
                text, cursor = self._path_autocomplete(text, cursor)
            elif key == curses.KEY_RESIZE:
                pass
            elif 32 <= key <= 126:
                text = text[:cursor] + chr(key) + text[cursor:]
                cursor += 1

        curses.curs_set(0)
        return None

    @staticmethod
    def _path_autocomplete(text: str, cursor: int) -> tuple[str, int]:
        try:
            p = Path(text).expanduser()
            if p.is_dir():
                entries = sorted(p.iterdir())
                if entries:
                    text = str(entries[0])
                    if entries[0].is_dir():
                        text += os.sep
                    cursor = len(text)
            else:
                parent = p.parent
                prefix = p.name
                if parent.is_dir():
                    matches = sorted(
                        e
                        for e in parent.iterdir()
                        if e.name.startswith(prefix)
                    )
                    if matches:
                        text = str(matches[0])
                        if matches[0].is_dir():
                            text += os.sep
                        cursor = len(text)
        except OSError:
            pass
        return text, cursor

    # ── confirmation dialog ─────────────────────────────────────────

    def _confirm(
        self, title: str, message: str, options: list[str] | None = None
    ) -> int:
        """Modal dialog.  Returns selected index or -1 on Esc."""
        if options is None:
            options = ["Yes", "No"]
        selected = len(options) - 1  # default to last (usually Cancel)

        while True:
            self.stdscr.clear()
            h, w = self.stdscr.getmaxyx()

            self._safe_addnstr(
                1,
                2,
                title,
                w - 4,
                curses.color_pair(self.COLOR_WARN) | curses.A_BOLD,
            )

            lines: list[str] = []
            for raw_line in message.split("\n"):
                while len(raw_line) > w - 4:
                    lines.append(raw_line[: w - 4])
                    raw_line = raw_line[w - 4 :]
                lines.append(raw_line)

            for i, line in enumerate(lines):
                y = 3 + i
                if y >= h - len(options) - 3:
                    break
                self._safe_addnstr(y, 2, line, w - 4)

            opt_y = 3 + len(lines) + 1
            for i, opt in enumerate(options):
                if opt_y + i >= h - 2:
                    break
                if i == selected:
                    self._safe_addnstr(
                        opt_y + i,
                        4,
                        f" \u25b8 {opt} ",
                        w - 6,
                        curses.color_pair(self.COLOR_SELECT),
                    )
                else:
                    self._safe_addnstr(opt_y + i, 4, f"   {opt}", w - 6)

            self._draw_footer(
                "\u2191\u2193/jk: Navigate  Enter: Confirm  Esc: Cancel"
            )
            self.stdscr.refresh()

            key = self.stdscr.getch()
            if key == 27:
                return -1
            elif self._key_up(key):
                selected = (selected - 1) % len(options)
            elif self._key_down(key):
                selected = (selected + 1) % len(options)
            elif self._key_enter(key):
                return selected
            elif key == curses.KEY_RESIZE:
                pass

    # ── main menu ───────────────────────────────────────────────────

    def run(self) -> None:
        h, w = self.stdscr.getmaxyx()
        if h < 10 or w < 40:
            self.stdscr.clear()
            self._safe_addnstr(
                0,
                0,
                "Terminal too small (min 40\u00d710)",
                40,
                curses.color_pair(self.COLOR_WARN),
            )
            self.stdscr.getch()
            return
        self._main_menu()

    def _main_menu(self) -> None:
        menu: list[tuple[str, object]] = [
            ("Map a Directory", self._flow_map),
            ("Compare Two Maps", self._flow_compare),
            ("Report Duplicates", self._flow_report),
            ("Quit", None),
        ]
        selected = 0

        while self.running:
            self.stdscr.clear()
            h, w = self.stdscr.getmaxyx()

            title = " Checksum Mapper TUI "
            self._safe_addnstr(
                0,
                max(0, (w - len(title)) // 2),
                title,
                w,
                curses.color_pair(self.COLOR_HEADER) | curses.A_BOLD,
            )
            self._safe_addnstr(1, 0, "\u2500" * w, w - 1)

            for i, (label, _) in enumerate(menu):
                y = 3 + i * 2
                if y >= h - 3:
                    break
                if i == selected:
                    self._safe_addnstr(
                        y,
                        2,
                        f" \u25b8 {label} ".ljust(w - 4),
                        w - 4,
                        curses.color_pair(self.COLOR_SELECT),
                    )
                else:
                    self._safe_addnstr(y, 2, f"   {label}", w - 4)

            self._draw_status()
            self._draw_footer(
                "\u2191\u2193/jk: Navigate  Enter/l: Select  q: Quit"
            )
            self.stdscr.refresh()

            key = self.stdscr.getch()
            if self._key_quit(key):
                self.running = False
            elif self._key_up(key):
                selected = (selected - 1) % len(menu)
            elif self._key_down(key):
                selected = (selected + 1) % len(menu)
            elif self._key_enter(key) or self._key_right(key):
                if menu[selected][1] is None:
                    self.running = False
                else:
                    menu[selected][1]()
            elif key == curses.KEY_RESIZE:
                pass

    # ── workflow: map ───────────────────────────────────────────────

    def _flow_map(self) -> None:
        dir_path = self._text_input(
            "Enter directory path to scan:", str(Path.cwd())
        )
        if dir_path is None:
            return

        path = Path(dir_path).expanduser().resolve()
        if not path.is_dir():
            self.status_msg = f"ERROR: Not a directory: {path}"
            return

        threads_str = self._text_input("Number of threads (default 1):", "1")
        if threads_str is None:
            return
        try:
            num_threads = max(1, int(threads_str))
        except ValueError:
            num_threads = 1

        mapper = ChecksumMapper(verbose=False)
        processed = [0]
        total_files = [0]
        errors: list[str] = []
        scan_done = [False]

        def _worker() -> None:
            with ThreadPoolExecutor(max_workers=num_threads) as executor:
                futures: dict = {}
                for fi in traverse(path):
                    total_files[0] += 1
                    futures[executor.submit(mapper.add, fi)] = fi
                for future in as_completed(futures):
                    fi = futures[future]
                    try:
                        future.result()
                    except Exception as exc:
                        errors.append(f"{fi.path}: {exc}")
                    processed[0] += 1
            scan_done[0] = True

        t = threading.Thread(target=_worker, daemon=True)
        t.start()

        self.stdscr.nodelay(True)
        while not scan_done[0]:
            self.stdscr.clear()
            h, w = self.stdscr.getmaxyx()

            self._safe_addnstr(
                1,
                2,
                f"Scanning: {path}",
                w - 4,
                curses.color_pair(self.COLOR_HEADER) | curses.A_BOLD,
            )

            done = processed[0]
            total = max(total_files[0], 1)
            pct = (
                min(100, int(done / total * 100)) if total_files[0] > 0 else 0
            )
            bar_w = min(w - 12, 50)
            filled = int(bar_w * pct / 100)
            bar = "\u2588" * filled + "\u2591" * (bar_w - filled)
            self._safe_addnstr(3, 2, f"[{bar}] {pct:3d}%", w - 4)
            self._safe_addnstr(
                4, 2, f"Files: {done}/{total_files[0] or '?'}", w - 4
            )

            if errors:
                self._safe_addnstr(
                    6,
                    2,
                    f"Errors: {len(errors)}",
                    w - 4,
                    curses.color_pair(self.COLOR_WARN),
                )

            self._draw_footer("Scanning in progress...")
            self.stdscr.refresh()

            try:
                self.stdscr.getch()
            except curses.error:
                pass
            time.sleep(0.1)

        self.stdscr.nodelay(False)
        t.join()

        save_path = Path.cwd() / f"checksum_map_{int(time.time())}.json"
        mapper.save(save_path, indent=2)
        duplicates = mapper.get_duplicates()
        if duplicates:
            self.status_msg = f"INFO: Saved map to {save_path.name}"
            self._show_results(f"Duplicates in {path.name}", duplicates)
        else:
            self.status_msg = (
                f"INFO: No duplicates. Map saved to {save_path.name}"
            )

    # ── workflow: compare ───────────────────────────────────────────

    def _flow_compare(self) -> None:
        p1 = self._text_input("Path to first checksum map (JSON):")
        if p1 is None:
            return
        p2 = self._text_input("Path to second checksum map (JSON):")
        if p2 is None:
            return

        try:
            m1 = ChecksumMapper(verbose=False)
            m2 = ChecksumMapper(verbose=False)
            m1.load(Path(p1).expanduser().resolve())
            m2.load(Path(p2).expanduser().resolve())
        except (FileNotFoundError, json.JSONDecodeError, KeyError) as e:
            self.status_msg = f"ERROR: {e}"
            return

        common = m1.compare(m2)
        if common:
            self._show_results("Common Checksums", common)
        else:
            self.status_msg = "INFO: No common checksums found."

    # ── workflow: report ────────────────────────────────────────────

    def _flow_report(self) -> None:
        p = self._text_input("Path to checksum map (JSON):")
        if p is None:
            return

        map_path = Path(p).expanduser().resolve()

        try:
            mapper = ChecksumMapper(verbose=False)
            mapper.load(map_path)
        except (FileNotFoundError, json.JSONDecodeError, KeyError) as e:
            self.status_msg = f"ERROR: {e}"
            return

        dups = mapper.get_duplicates()
        if dups:
            self._show_results(
                "Duplicates Report",
                dups,
                report_mapper=mapper,
                report_path=map_path,
            )
        else:
            self.status_msg = "INFO: No duplicates found."

    # ── results browser ─────────────────────────────────────────────

    def _show_results(
        self,
        title: str,
        data: dict,
        report_mapper: ChecksumMapper | None = None,
        report_path: Path | None = None,
    ) -> None:
        """Interactive tree browser for checksum groups."""

        def _build_groups(source_data: dict) -> list[dict]:
            groups: list[dict] = []
            for cs, entries in source_data.items():
                files: list[FileInfo] = []
                for e in entries:
                    if isinstance(e, FileInfo):
                        files.append(e)
                    elif isinstance(e, dict):
                        fi = _parse_file_info(e)
                        if fi:
                            files.append(fi)
                    else:
                        files.append(
                            FileInfo(name=str(e), size=0, path=Path(str(e)))
                        )
                if files:
                    groups.append({"checksum": cs, "files": files})
            return groups

        def _save_report() -> bool:
            if report_mapper is None or report_path is None:
                return False
            try:
                report_mapper.save(report_path, indent=2)
            except OSError as exc:
                self.status_msg = f"ERROR: Could not update report: {exc}"
                return False
            return True

        groups = _build_groups(data)
        report_mode = report_mapper is not None and report_path is not None

        if not groups:
            self.status_msg = "INFO: Nothing to display."
            return

        expanded: set = set()  # checksums currently expanded
        cursor = 0
        scroll = 0
        search = ""

        def _flat() -> list[tuple[str, int, int | None, str]]:
            rows: list[tuple[str, int, int | None, str]] = []
            for gi, grp in enumerate(groups):
                cs = grp["checksum"]
                fl = grp["files"]
                if search and not any(
                    search.lower() in str(f.path).lower() for f in fl
                ):
                    continue
                is_exp = cs in expanded
                arrow = "\u25bc" if is_exp else "\u25b6"
                sz = self._format_size(fl[0].size) if fl and fl[0].size else ""
                label = (
                    f"{arrow} {self._format_checksum(cs)}  ({len(fl)} files"
                )
                if sz:
                    label += f", ~{sz} each"
                label += ")"
                rows.append(("group", gi, None, label))
                if is_exp:
                    for fi_i, fi in enumerate(fl):
                        rows.append(
                            (
                                "file",
                                gi,
                                fi_i,
                                f"    {fi.path}"
                                f"  ({self._format_size(fi.size)})",
                            )
                        )
            return rows

        while True:
            rows = _flat()
            if not rows:
                self.status_msg = "INFO: No matching entries."
                return

            self.stdscr.clear()
            h, w = self.stdscr.getmaxyx()
            body_h = h - 4

            cursor = max(0, min(cursor, len(rows) - 1))
            if cursor < scroll:
                scroll = cursor
            elif cursor >= scroll + body_h:
                scroll = cursor - body_h + 1

            # header
            self._safe_addnstr(
                0,
                0,
                f" {title} ".center(w),
                w - 1,
                curses.color_pair(self.COLOR_HEADER) | curses.A_BOLD,
            )
            if search:
                self._safe_addnstr(
                    1, 0, f" Filter: {search}", w - 1, curses.A_DIM
                )

            # body
            for i in range(body_h):
                ri = scroll + i
                if ri >= len(rows):
                    break
                rtype, gi, fi_i, text = rows[ri]
                y = 2 + i

                if ri == cursor:
                    attr = curses.color_pair(self.COLOR_SELECT)
                    self._safe_addnstr(
                        y, 0, text[: w - 1].ljust(w - 1), w - 1, attr
                    )
                else:
                    attr = (
                        curses.color_pair(self.COLOR_GROUP) | curses.A_BOLD
                        if rtype == "group"
                        else 0
                    )
                    self._safe_addnstr(y, 0, text[: w - 1], w - 1, attr)

            self._draw_status()
            self._draw_footer(
                "\u2191\u2193/jk:Nav  Enter/l:Expand  o:Open  d:Del"
                "  /:Search  r:Refresh  q:Back  g/G:Top/Bot"
                if report_mode
                else "\u2191\u2193/jk:Nav  Enter/l:Expand  o:Open  d:Del"
                "  /:Search  q:Back  g/G:Top/Bot"
            )
            self.stdscr.refresh()

            key = self.stdscr.getch()
            if self._key_quit(key):
                return
            elif self._key_up(key):
                cursor = max(0, cursor - 1)
            elif self._key_down(key):
                cursor = min(len(rows) - 1, cursor + 1)
            elif key == curses.KEY_PPAGE:
                cursor = max(0, cursor - body_h)
            elif key == curses.KEY_NPAGE:
                cursor = min(len(rows) - 1, cursor + body_h)
            elif key == ord("g"):
                cursor = 0
            elif key == ord("G"):
                cursor = len(rows) - 1
            elif self._key_enter(key) or self._key_right(key):
                rtype, gi, fi_i, _ = rows[cursor]
                if rtype == "group":
                    cs = groups[gi]["checksum"]
                    expanded.symmetric_difference_update({cs})
                else:
                    self._file_action(
                        groups,
                        gi,
                        fi_i,
                        expanded,
                        report_mapper,
                        report_path,
                    )
            elif self._key_left(key):
                rtype, gi, fi_i, _ = rows[cursor]
                if rtype == "file":
                    cs = groups[gi]["checksum"]
                    expanded.discard(cs)
                    # jump cursor to parent group
                    for ri2, r in enumerate(rows):
                        if r[0] == "group" and r[1] == gi:
                            cursor = ri2
                            break
                elif rtype == "group":
                    cs = groups[gi]["checksum"]
                    if cs in expanded:
                        expanded.discard(cs)
                    else:
                        return  # back to menu
            elif key == ord("o"):
                rtype, gi, fi_i, _ = rows[cursor]
                if rtype == "file":
                    self._open_file(groups[gi]["files"][fi_i])
            elif key == ord("d"):
                rtype, gi, fi_i, _ = rows[cursor]
                if rtype == "file":
                    self._file_delete(
                        groups,
                        gi,
                        fi_i,
                        expanded,
                        report_mapper,
                        report_path,
                    )
            elif key == ord("/"):
                search = self._search_input() or ""
                cursor = 0
                scroll = 0
            elif key == ord("r") and report_mode:
                refreshed_count, missing_count, error_count = (
                    report_mapper.refresh_reported_duplicates()
                )
                if _save_report():
                    groups = _build_groups(report_mapper.get_duplicates())
                    expanded.intersection_update(
                        {group["checksum"] for group in groups}
                    )
                    cursor = 0
                    scroll = 0
                    if groups:
                        self.status_msg = (
                            "INFO: Report recalculated and updated "
                            f"({refreshed_count} files refreshed"
                            f", {missing_count} missing"
                            f", {error_count} errors)."
                        )
                    else:
                        self.status_msg = (
                            "INFO: Report recalculated and updated;"
                            " no duplicates remain."
                        )
                        return
            elif key == curses.KEY_RESIZE:
                pass

    # ── file actions ────────────────────────────────────────────────

    def _file_action(
        self,
        groups: list[dict],
        gi: int,
        fi_i: int,
        expanded: set,
        report_mapper: ChecksumMapper | None = None,
        report_path: Path | None = None,
    ) -> None:
        fi = groups[gi]["files"][fi_i]
        choice = self._confirm(
            f"Actions for: {fi.name}",
            f"Path: {fi.path}\nSize: {self._format_size(fi.size)}",
            [f"Open: {fi.name}", f"Delete: {fi.name}", "Cancel"],
        )
        if choice == 0:
            self._open_file(fi)
        elif choice == 1:
            self._file_delete(
                groups,
                gi,
                fi_i,
                expanded,
                report_mapper,
                report_path,
            )

    def _open_file(self, fi: FileInfo) -> None:
        if not fi.path.exists():
            self.status_msg = f"ERROR: File not found: {fi.path}"
            return
        try:
            if IS_WINDOWS:
                os.startfile(str(fi.path))
            elif IS_MACOS:
                subprocess.Popen(
                    ["open", str(fi.path)],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
            else:
                subprocess.Popen(
                    ["xdg-open", str(fi.path)],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
            self.status_msg = f"INFO: Opened {fi.name}"
        except FileNotFoundError:
            if IS_MACOS:
                self.status_msg = "ERROR: open command not available"
            else:
                self.status_msg = "ERROR: xdg-open not available"
        except AttributeError:
            self.status_msg = "ERROR: os.startfile is not available"
        except OSError as e:
            self.status_msg = f"ERROR: {e}"

    def _file_delete(
        self,
        groups: list[dict],
        gi: int,
        fi_i: int,
        expanded: set,
        report_mapper: ChecksumMapper | None = None,
        report_path: Path | None = None,
    ) -> None:
        fi = groups[gi]["files"][fi_i]
        if not fi.path.exists():
            self.status_msg = f"ERROR: File not found: {fi.path}"
            return
        choice = self._confirm(
            "Delete File",
            f"Are you sure?\n{fi.path}\nSize: {self._format_size(fi.size)}",
            ["Move to Trash", "Delete Permanently", "Cancel"],
        )
        removed = False
        if choice == 0:
            removed = self._trash(fi.path)
        elif choice == 1:
            removed = self._unlink(fi.path)
        if removed:
            if report_mapper is not None and report_path is not None:
                report_mapper.remove_file(fi.path)
                try:
                    report_mapper.save(report_path, indent=2)
                    self.status_msg += " Report updated."
                except OSError as exc:
                    self.status_msg = (
                        f"ERROR: File deleted, but report update failed: {exc}"
                    )
            groups[gi]["files"].pop(fi_i)
            if report_mapper is not None and report_path is not None:
                if len(groups[gi]["files"]) < 2:
                    expanded.discard(groups[gi]["checksum"])
                    groups.pop(gi)
            elif not groups[gi]["files"]:
                expanded.discard(groups[gi]["checksum"])
                groups.pop(gi)

    def _trash(self, path: Path) -> bool:
        """Move a file to the platform trash when available."""
        if IS_WINDOWS:
            return self._trash_windows(path)
        trash_files = Path.home() / ".local" / "share" / "Trash" / "files"
        trash_info = Path.home() / ".local" / "share" / "Trash" / "info"
        try:
            trash_files.mkdir(parents=True, exist_ok=True)
            trash_info.mkdir(parents=True, exist_ok=True)
        except OSError as e:
            self.status_msg = f"ERROR: {e}"
            return False

        dest_name = path.name
        dest = trash_files / dest_name
        n = 1
        while dest.exists():
            dest_name = f"{path.stem}.{n}{path.suffix}"
            dest = trash_files / dest_name
            n += 1

        info_text = (
            "[Trash Info]\n"
            f"Path={path.resolve()}\n"
            f"DeletionDate={datetime.now().strftime('%Y-%m-%dT%H:%M:%S')}\n"
        )
        info_path = trash_info / f"{dest_name}.trashinfo"
        try:
            info_path.write_text(info_text)
            path.rename(dest)
            self.status_msg = f"INFO: Trashed {path.name}"
            return True
        except OSError as e:
            info_path.unlink(missing_ok=True)
            self.status_msg = f"ERROR: {e}"
            return False

    def _trash_windows(self, path: Path) -> bool:
        """Move a file to the Windows Recycle Bin using shell APIs."""
        operation = SHFILEOPSTRUCTW()
        operation.wFunc = FO_DELETE
        operation.pFrom = f"{path.resolve()}\0\0"
        operation.fFlags = (
            FOF_ALLOWUNDO | FOF_NOCONFIRMATION | FOF_NOERRORUI | FOF_SILENT
        )

        result = ctypes.windll.shell32.SHFileOperationW(
            ctypes.byref(operation)
        )
        if result != 0 or operation.fAnyOperationsAborted:
            self.status_msg = f"ERROR: Could not trash {path.name}"
            return False

        self.status_msg = f"INFO: Trashed {path.name}"
        return True

    def _unlink(self, path: Path) -> bool:
        """Permanently delete a file."""
        try:
            path.unlink()
            self.status_msg = f"INFO: Deleted {path.name}"
            return True
        except OSError as e:
            self.status_msg = f"ERROR: {e}"
            return False

    # ── search ──────────────────────────────────────────────────────

    def _search_input(self) -> str | None:
        """Inline search bar.  Returns filter text or None on Esc."""
        curses.curs_set(1)
        text = ""

        while True:
            h, w = self.stdscr.getmaxyx()
            y = h - 2
            prompt = f" /: {text}"
            self._safe_addnstr(
                y,
                0,
                prompt.ljust(w),
                w - 1,
                curses.color_pair(self.COLOR_GROUP),
            )
            try:
                self.stdscr.move(y, min(len(prompt), w - 1))
            except curses.error:
                pass
            self.stdscr.refresh()

            key = self.stdscr.getch()
            if key == 27:
                curses.curs_set(0)
                return None
            elif self._key_enter(key):
                curses.curs_set(0)
                return text
            elif self._key_backspace(key):
                text = text[:-1]
            elif 32 <= key <= 126:
                text += chr(key)

        curses.curs_set(0)
        return None


def tui_handler(args: argparse.Namespace) -> None:
    """Launch the interactive TUI."""
    if not HAS_CURSES:
        print("ERROR: curses library not available.", file=sys.stderr)
        print(
            "On Windows, install: pip install windows-curses",
            file=sys.stderr,
        )
        sys.exit(1)
    curses.wrapper(lambda stdscr: TuiApp(stdscr).run())


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Checksum Mapper")

    subparsers = parser.add_subparsers(required=True)

    map_parser = subparsers.add_parser(
        "map", help="Map checksums in a directory"
    )
    map_parser.add_argument("directory", type=str, help="Directory to scan")
    map_parser.add_argument(
        "--threads",
        type=int,
        default=NUMBER_OF_THREADS,
        help="Number of threads to use (default: 1)",
    )
    map_parser.set_defaults(func=map_handler)

    compare_parser = subparsers.add_parser(
        "compare", help="Compare two checksum maps"
    )
    compare_parser.add_argument(
        "map1", type=str, help="Path to the first checksum map (JSON)"
    )
    compare_parser.add_argument(
        "map2", type=str, help="Path to the second checksum map (JSON)"
    )
    compare_parser.set_defaults(func=compare_handler)

    report_parser = subparsers.add_parser(
        "report", help="Generate a report of duplicates from a checksum map"
    )
    report_parser.add_argument(
        "map", type=str, help="Path to the checksum map (JSON)"
    )
    report_parser.set_defaults(func=report_handler)

    tui_parser = subparsers.add_parser(
        "tui", help="Launch interactive TUI mode"
    )
    tui_parser.set_defaults(func=tui_handler)

    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None):
    args = parse_args(argv)
    args.func(args)


if __name__ == "__main__":
    sys.exit(main())
