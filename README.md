# Recrep

**Recrep** is a Bash-based reconnaissance tool designed to automate common reconnaissance tasks for **authorized security testing**.

It combines subdomain discovery, HTTP probing, and automated scanning into a single workflow.

> ⚠️ **Disclaimer:** Recrep is intended for authorized security testing, CTFs, labs, and educational purposes only. Only scan systems and domains you have explicit permission to test.

# Features

* Simple and lightweight Bash-based reconnaissance tool.
* Automated subdomain discovery and HTTP probing.
* Supports single-domain and list-based targets.
* Configurable request rate for automated scanning.
* Organized output directories for reconnaissance results.
* Provides HTTP status codes and response information.
* Supports customizable output directories.
* Simple command-line interface.
* Designed for Linux and other Bash-compatible environments.

# Requirements

Recrep requires **Bash** and the external tools used by the reconnaissance workflow.

Make sure all required dependencies are installed and available in your `PATH` before running Recrep.

# Installation Instructions

Clone the repository:

```bash
git clone https://github.com/travissaper/recrep.git
cd recrep
```

Make the script executable:

```bash
chmod +x recrep.sh
```

You can now run Recrep directly:

```bash
./recrep.sh -h
```

## Installing to PATH

To run Recrep from any directory using:

```bash
recrep
```

create a local executable directory:

```bash
mkdir -p ~/.local/bin
```

Copy Recrep into it:

```bash
cp recrep.sh ~/.local/bin/recrep
chmod +x ~/.local/bin/recrep
```

Add `~/.local/bin` to your `PATH`.

### Bash

Add the following to `~/.bashrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then reload your shell:

```bash
source ~/.bashrc
```

### Zsh

If you use Zsh, add the following to `~/.zshrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then reload your shell:

```bash
source ~/.zshrc
```

Verify the installation:

```bash
which recrep
```

You should see something similar to:

```text
/home/username/.local/bin/recrep
```

You can then run:

```bash
recrep -h
```

# Updating

If you installed Recrep by cloning the repository, update it with:

```bash
cd recrep
git pull
cp recrep.sh ~/.local/bin/recrep
chmod +x ~/.local/bin/recrep
```

# Usage

Display the help menu:

```bash
recrep -h
```

Run Recrep against a single domain:

```bash
recrep -d example.com
```

Set a custom request rate:

```bash
recrep -d example.com -t 10
```

Recrep will perform the configured reconnaissance workflow and organize the results into the appropriate output directory.

# Example Output

```text
Automated scanning: 10 Requests per second
Target: example.com
Date: 2026-08-10

[https://app.example.com] [404] [404 Not Found]

[https://api.example.com] [200] [OK]

[https://www.example.com] [301] [Moved Permanently]
```

# Output

Recrep organizes reconnaissance results into an output directory.

A typical output structure may look like:

```text
recon_example.com/
├── subdomains.txt
├── live.txt
├── results.txt
└── ...
```

The exact output files and directory structure may vary depending on the options used.

# Options

Run:

```bash
recrep -h
```

to display all available options and switches supported by the current version of Recrep.

Example:

```text
Usage: recrep [options]

Options:
    -d <domain>     Target a single domain
    -t <rate>       Set requests per second
    -o <directory>  Set output directory
    -h              Show help
```

> Keep this section synchronized with the `usage()` function in `recrep.sh`.

# Troubleshooting

### `recrep: command not found`

Check whether `~/.local/bin` is included in your `PATH`:

```bash
echo $PATH
```

If it is missing, add:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

to your `~/.bashrc` or `~/.zshrc`, then reload your shell.

### `Permission denied`

Make sure the script is executable:

```bash
chmod +x ~/.local/bin/recrep
```

### Check the installed executable

```bash
which recrep
```

You can also use:

```bash
type -a recrep
```

This can help identify multiple installations of Recrep.

# Contributing

Contributions, bug reports, and improvements are welcome.

To contribute:

```bash
git clone https://github.com/travissaper/recrep.git
cd recrep
```

Create a new branch:

```bash
git checkout -b feature/my-feature
```

Make your changes, test them, and commit:

```bash
git add .
git commit -m "Add my feature"
```

Push your branch:

```bash
git push origin feature/my-feature
```

Then open a Pull Request.

# License

This project is licensed under the **MIT License**.

See `LICENSE` for more information.

# Disclaimer

Recrep is provided for educational and authorized security testing purposes.

You are responsible for ensuring that you have permission to scan any systems, domains, networks, or infrastructure you target.

The author is not responsible for misuse of this tool.
