{
  description = "BURAI - A GUI system for Quantum ESPRESSO";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        
        # Java development environment with JavaFX support
        jdk = pkgs.openjdk17.override {
          enableJavaFX = true;
        };
        
        # External dependencies classpath
        libClasspath = "lib/exp4j-0.4.6.jar:lib/gson-2.6.1.jar:lib/jcodec-0.2.0.jar:lib/jcodec-javase-0.2.0.jar:lib/jsch-0.1.54.jar";
        
        # Build script for the application
        buildScript = pkgs.writeShellScriptBin "burai-build" ''
          #!/usr/bin/env bash
          set -e
          
          echo "Building BURAI..."
          
          # Create class output directory if it doesn't exist
          mkdir -p class
          
          # Compile Java sources
          echo "Compiling Java sources..."
          find src -name "*.java" > sources.txt
          ${jdk}/bin/javac \
            -d class \
            -sourcepath src \
            -cp "${libClasspath}" \
            @sources.txt
          rm sources.txt
          
          echo "Build completed successfully!"
          echo "Compiled classes are in ./class directory"
        '';
        
        # Run script for the application
        runScript = pkgs.writeShellScriptBin "burai-run" ''
          #!/usr/bin/env bash
          set -e
          
          if [ ! -d "class" ] || [ -z "$(ls -A class)" ]; then
            echo "No compiled classes found. Running build first..."
            burai-build
          fi
          
          echo "Starting BURAI..."
          ${jdk}/bin/java \
            -cp "class:${libClasspath}" \
            burai.app.QEFXMain "$@"
        '';
        
        # Clean script
        cleanScript = pkgs.writeShellScriptBin "burai-clean" ''
          #!/usr/bin/env bash
          echo "Cleaning build artifacts..."
          rm -rf class
          echo "Clean completed!"
        '';
        
        # Package JAR script
        jarScript = pkgs.writeShellScriptBin "burai-jar" ''
          #!/usr/bin/env bash
          set -e
          
          if [ ! -d "class" ] || [ -z "$(ls -A class)" ]; then
            echo "No compiled classes found. Running build first..."
            burai-build
          fi
          
          echo "Creating JAR file with embedded dependencies..."
          
          # Create a temporary directory for JAR contents
          mkdir -p /tmp/burai-jar
          cp -r class/* /tmp/burai-jar/
          
          # Extract library JARs into temporary directory
          cd /tmp/burai-jar
          for jar in ../../lib/*.jar; do
            ${jdk}/bin/jar -xf "$jar"
          done
          
          # Remove signature files that may cause conflicts
          find . -name "*.SF" -o -name "*.DSA" -o -name "*.RSA" -delete
          
          # Create the final JAR
          cd -
          ${jdk}/bin/jar --create \
            --file burai.jar \
            --main-class burai.app.QEFXMain \
            -C /tmp/burai-jar .
          
          # Clean up
          rm -rf /tmp/burai-jar
          
          echo "JAR created: burai.jar"
        '';
        
      in
      {
        # Development shell
        devShells.default = pkgs.mkShell {
          name = "burai-dev-shell";
          
          buildInputs = [
            jdk
            pkgs.ant
            pkgs.git
            buildScript
            runScript
            cleanScript
            jarScript
          ];
          
          shellHook = ''
            echo "================================================"
            echo "BURAI Development Environment"
            echo "================================================"
            echo ""
            echo "Java version:"
            java -version
            echo ""
            echo "Available commands:"
            echo "  burai-build  - Compile the Java sources"
            echo "  burai-run    - Run the application"
            echo "  burai-clean  - Clean build artifacts"
            echo "  burai-jar    - Create a JAR file"
            echo "  ant          - Run Ant build tool"
            echo ""
            echo "Project structure:"
            echo "  src/         - Java source files"
            echo "  lib/         - External JAR dependencies"
            echo "  class/       - Compiled class files (generated)"
            echo ""
            echo "To get started:"
            echo "  1. Run 'burai-build' to compile the project"
            echo "  2. Run 'burai-run' to start the application"
            echo "================================================"
          '';
          
          # Environment variables
          JAVA_HOME = "${jdk}";
          CLASSPATH = "./class:${libClasspath}";
        };
        
        # Default package (optional - for building the application as a Nix package)
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "burai";
          version = "1.3.2";
          
          src = ./.;
          
          nativeBuildInputs = [ jdk ];
          
          buildPhase = ''
            # Create class output directory
            mkdir -p class
            
            # Compile Java sources
            find src -name "*.java" > sources.txt
            javac \
              -d class \
              -sourcepath src \
              -cp "${libClasspath}" \
              @sources.txt
          '';
          
          installPhase = ''
            mkdir -p $out/bin $out/share/burai
            
            # Copy compiled classes and libraries
            cp -r class $out/share/burai/
            cp -r lib $out/share/burai/
            
            # Create wrapper script
            # Build classpath with proper prefix
            INSTALL_CLASSPATH="$out/share/burai/class"
            for jar in lib/*.jar; do
              INSTALL_CLASSPATH="$INSTALL_CLASSPATH:$out/share/burai/$jar"
            done
            
            cat > $out/bin/burai << EOF
            #!${pkgs.bash}/bin/bash
            exec ${jdk}/bin/java \
              -cp "$INSTALL_CLASSPATH" \
              burai.app.QEFXMain "\$@"
            EOF
            
            chmod +x $out/bin/burai
          '';
          
          meta = with pkgs.lib; {
            description = "A GUI system for Quantum ESPRESSO";
            homepage = "https://github.com/tellmeY18/burai";
            license = licenses.asl20;
            platforms = platforms.unix;
          };
        };
      }
    );
}
