# Nix Development Environment Setup

This project includes a `flake.nix` configuration that provides a complete development environment for the BURAI Java application.

## Prerequisites

You need to have Nix installed with flakes enabled:

1. Install Nix (if not already installed):
   ```bash
   curl -L https://nixos.org/nix/install | sh
   ```

2. Enable flakes by adding the following to `~/.config/nix/nix.conf`:
   ```
   experimental-features = nix-command flakes
   ```

## Quick Start

### Enter the Development Shell

```bash
nix develop
```

This will drop you into a shell with all necessary dependencies (Java, Ant, build scripts) available.

### Build the Project

```bash
nix develop
burai-build
```

Or in one command:
```bash
nix develop --command burai-build
```

### Run the Application

```bash
nix develop
burai-run
```

### Clean Build Artifacts

```bash
nix develop
burai-clean
```

### Create a JAR File

```bash
nix develop
burai-jar
```

## Building as a Nix Package

You can also build BURAI as a standalone Nix package:

```bash
nix build
```

This will create a `result` symlink pointing to the build output with a `burai` executable in `result/bin/burai`.

Run the built package:
```bash
./result/bin/burai
```

## Development Workflow

1. Enter the development shell:
   ```bash
   nix develop
   ```

2. Make changes to the source code in `src/`

3. Build and test:
   ```bash
   burai-build
   burai-run
   ```

4. Clean and rebuild as needed:
   ```bash
   burai-clean
   burai-build
   ```

## What's Included

The development environment provides:

- **JDK 17** with JavaFX support (compatible with Java 8+ requirements)
- **Apache Ant** for legacy build scripts
- **Git** for version control
- **Custom build scripts**:
  - `burai-build` - Compiles all Java sources
  - `burai-run` - Runs the application
  - `burai-clean` - Removes build artifacts
  - `burai-jar` - Creates a JAR file

## Environment Variables

When you enter the development shell, the following environment variables are set:

- `JAVA_HOME` - Points to the JDK installation
- `CLASSPATH` - Includes all required JAR dependencies

## Dependencies

The following external libraries are automatically included in the classpath:

- exp4j-0.4.6.jar
- gson-2.6.1.jar
- jcodec-0.2.0.jar
- jcodec-javase-0.2.0.jar
- jsch-0.1.54.jar

## Using with direnv (Optional)

For automatic environment activation when entering the directory, you can use direnv:

1. Install direnv
2. Create a `.envrc` file with:
   ```bash
   use flake
   ```
3. Run `direnv allow`

Now the environment will be automatically loaded when you `cd` into the directory.

## Troubleshooting

### Flakes not enabled

If you get an error about flakes not being recognized, make sure you have enabled the experimental feature:

```bash
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### JavaFX issues

If you encounter JavaFX-related errors, ensure you're using the provided JDK from the Nix environment (JDK 17 with JavaFX enabled), not a system-installed Java.

### Build failures

Try cleaning and rebuilding:
```bash
burai-clean
burai-build
```

## More Information

- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
- [BURAI Project](https://github.com/tellmeY18/burai)
