# Contributing to PiPlayer

Thank you for your interest in contributing to **PiPlayer**! We welcome open-source contributions from developers, designers, and Raspberry Pi enthusiasts around the world.

## How to Contribute

1. **Fork the Repository**: Create your own fork of the repository on GitHub.
2. **Clone your Fork**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/raspberry-pi-music-player.git
   cd raspberry-pi-music-player
   ```
3. **Create a Feature Branch**:
   ```bash
   git checkout -b feature/amazing-new-feature
   ```
4. **Make & Test your Changes**:
   - Ensure code follows clean modular structure.
   - Run backend test suite:
     ```bash
     python -m unittest discover -s tests -p "test_*.py"
     ```
5. **Commit & Push**:
   ```bash
   git commit -m "feat: add awesome new feature"
   git push origin feature/amazing-new-feature
   ```
6. **Open a Pull Request**: Submit your PR with a clear summary of your changes.

## Code Guidelines
- **UI Design**: Maintain the Black & White Neubrutalism design aesthetic with stark black containers (`#000000`), 2px/3px solid borders, and white accents (`#FFFFFF`).
- **Icons**: Use **Lucide Icons** exclusively (`data-lucide="..."`). Do not introduce raw emojis into the UI markup.
- **Backend API**: Keep FastAPI handlers async and broadcast state updates via WebSocket.

Thank you for building the best open-source Raspberry Pi music player!
