# EmojiPrompt

A Wayland and TTY-compatible password prompt that provides visual feedback through emojis or emoticons, helping users verify they've typed their password correctly.

## Features

- **Visual Password Feedback**: Instead of traditional asterisks, EmojiPrompt displays emojis or emoticons that are deterministically derived from your password
- **Two-Stage Verification**: 
  - While typing: Shows random "decoy" symbols that change with each keystroke
  - After first Enter: Displays the actual symbols derived from your password for verification
  - After second Enter: Submits the password
- **Dual Interface Support**:
  - Native Wayland interface with customizable themes
  - TTY fallback for terminal environments
- **Highly Customizable**:
  - Custom emoji sets for visual feedback
  - Custom emoticon sets for terminals without emoji support
  - Configurable colors and UI elements
  - Adjustable emoji size and count

## How It Works

When you type your password, EmojiPrompt generates a unique set of symbols based on the password content. The same password will always produce the same symbols, allowing you to visually verify you've typed it correctly before submission.

For example:
- Password "hello123" might show: 🌟 🎨 🚀
- Password "hello124" might show: 🌟 🎯 🎭

This immediate visual feedback helps catch typos before submitting incorrect passwords.

## Installation

### Requirements

- Zig 0.13.0 or later
- Wayland development libraries (for Wayland support)
- fcft library (for font rendering)
- pixman library (for image processing)
- xkbcommon library (for keyboard handling)

### Build from Source

```bash
git clone https://github.com/nilp0inter/wayprompt-emoji.git
cd wayprompt-emoji
zig build
```

The built executables will be in `zig-out/bin/`:
- `emojiprompt` - Main password prompt
- `pinentry-emojiprompt` - GnuPG pinentry implementation
- `emojiprompt-ssh-askpass` - SSH askpass implementation

### Install

```bash
zig build install
```

## Configuration

EmojiPrompt looks for configuration at:
- `$XDG_CONFIG_HOME/emojiprompt/config.ini`
- `~/.config/emojiprompt/config.ini`
- `/etc/emojiprompt/config.ini`

### Example Configuration

```ini
[general]
emoji-count = 5;
emoji-size = 32;
# Custom emoji set (comma-separated)
emoji-table = '🔒,🔑,🛡️,🔐,🔓';

[colours]
background = 0x1a1b26;
border = 0x6699CC;
text = 0xCCCCCC;
error-text = 0xF2777A;

[tty]
# Use emojis in TTY (auto-detects terminal support)
use-emoji = true;
# Custom emoticons for terminals without emoji support
emoticon = '^_^';
emoticon = 'O_O';
emoticon = '>_<';
emoticon = ':-)';
emoticon = ':-(';
emoticon = ':-D';
emoticon = ':-P';
emoticon = '*_*';
emoticon = 'T_T';
```

## Usage

### Basic Password Prompt

```bash
emojiprompt --get-pin --title "Password Required" --prompt "Enter password:"
```

### As SSH Askpass

```bash
export SSH_ASKPASS=/usr/local/bin/emojiprompt-ssh-askpass
export SSH_ASKPASS_REQUIRE=prefer
ssh-add
```

### As GnuPG Pinentry

Add to `~/.gnupg/gpg-agent.conf`:
```
pinentry-program /usr/local/bin/pinentry-emojiprompt
```

Then reload the agent:
```bash
gpg-connect-agent reloadagent /bye
```

### TTY Mode

When Wayland is not available, EmojiPrompt automatically falls back to TTY mode:

```bash
# Force TTY mode for testing
WAYLAND_DISPLAY="" DISPLAY="" emojiprompt --get-pin --prompt "Password:"
```

## Command Line Options

- `--get-pin`: Request password input
- `--title <text>`: Set window/prompt title
- `--prompt <text>`: Set prompt message
- `--description <text>`: Add description text
- `--error <text>`: Display error message
- `--ok <text>`: Set OK button text
- `--cancel <text>`: Set Cancel button text
- `--not-ok <text>`: Set Not OK button text

## Customization

### Emoji Sets

You can define custom emoji sets that match your preferences or theme:

```ini
# Security theme
emoji-table = '🔒,🔑,🛡️,🔐,🔓,🗝️,⚠️,🚨';

# Nature theme  
emoji-table = '🌸,🌺,🌻,🌷,🌹,🌵,🌲,🌴';

# Space theme
emoji-table = '🚀,🛸,🌟,⭐,🌙,☄️,🌍,🪐';
```

### Emoticon Sets

For terminals without emoji support, define custom ASCII emoticons:

```ini
[tty]
use-emoji = false;
emoticon = '^_^';
emoticon = 'o.O';
emoticon = '>:D';
emoticon = '¯\_(ツ)_/¯';
```

## Development

### Project Structure

- `src/` - Main source code
  - `emojiprompt-cli.zig` - Command-line interface
  - `emojiprompt-pinentry.zig` - GnuPG pinentry implementation
  - `Wayland.zig` - Wayland backend
  - `TTY.zig` - Terminal backend
  - `EmojiHash.zig` - Emoji generation logic
  - `Config.zig` - Configuration parser

### Testing

```bash
# Run tests
zig build test

# Test TTY mode
./test-tty.sh
```

## License

MIT License - See LICENSE file for details

## Credits

EmojiPrompt is a fork of [wayprompt](https://git.sr.ht/~leon_plickat/wayprompt) by Leon Henrik Plickat, enhanced with emoji-based password feedback functionality.
