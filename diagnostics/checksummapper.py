import argparse
import json
import sys
import time
import zlib
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from io import BufferedReader
from pathlib import Path
from pprint import pprint
from typing import Generator, Sequence, TypedDict

NUMBER_OF_THREADS = 1


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
    def __init__(self) -> None:
        self.checksum_map: dict[int, Entry] = {}

    def add(self, file_info: FileInfo) -> None:
        if file_info.checksum is None:
            with file_info.path.open("rb") as fd:
                file_info.checksum = crc32(fd)

        if file_info.checksum not in self.checksum_map:
            self.checksum_map[file_info.checksum] = {
                "checksum": file_info.checksum,
                "entries": [],
            }
        print(f"Processed {file_info.path}: {file_info.checksum}")
        self.checksum_map[file_info.checksum]["entries"].append(file_info)

    def get(self, checksum: int) -> list[FileInfo] | None:
        entry = self.checksum_map.get(checksum, None)
        if entry is not None:
            return entry["entries"]
        return None

    def save(self, path: Path, indent: int | None = None) -> None:
        with path.open("w") as fd:
            json.dump(self.checksum_map, fd, default=str, indent=indent)

    def load(self, path: Path) -> None:
        with path.open("r") as fd:
            self.checksum_map = json.load(fd)

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

    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None):
    args = parse_args(argv)
    args.func(args)


if __name__ == "__main__":
    sys.exit(main())
