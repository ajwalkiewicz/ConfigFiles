# Setup Brew
test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Add Go to PATH
if [ -d "$HOME/go/bin" ] ; then
    PATH="$PATH":$HOME/go/bin
fi

if [ -d "/usr/local/go/bin" ] ; then
    PATH="$PATH":/usr/local/go/bin
fi

# Set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# Set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi
