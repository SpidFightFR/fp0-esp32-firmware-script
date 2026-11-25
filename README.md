# fp0-esp32-firmware-script

I made this script when studying how the esp32 chip for the Flipper 0 works.

There are plenty of tools online that does a better job than what i did.

## Dependencies

- `uv`
- `curl`
- `wget`
- `jq`

# Usage

```
Usage: ./firmware-script.sh <option>

Options possible:
        help: Prints this help message.
        backup: Backups the current state of the board's flash into esp32-flash-backup.bin.
        restore: Flashes esp32-flash-backup.bin back into the board's flash chip.
        update: Fetches and flashes the latest firmware into the board's flash chip.
```

# Credits

- [fzeeflasher](https://fzeeflasher.com/) - you'll actually need this tool to make your esp32 chip work once, my script only updates the marauder app.
- [FZEasyMarauderFlash](https://github.com/SkeletonMan03/FZEasyMarauderFlash)
- [ESP32Marauder](https://github.com/justcallmekoko/ESP32Marauder)
- [UV Repository](https://github.com/astral-sh/uv)
