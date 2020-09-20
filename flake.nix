{
  description = "A pre release version of esphome";

  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;

  inputs.esphome = rec {
    url = "github:esphome/esphome?tag=v1.15.0b4";
    flake = false;
  };
    

  outputs = { self, nixpkgs, ... } @ inputs: {

    packages.x86_64-linux.esphome = 
      with import nixpkgs { system = "x86_64-linux"; };
      let
        python = python3.override {
          packageOverrides = self: super: {
            protobuf = super.protobuf.override {
              protobuf = protobuf3_13;
            };
          };
        };

      in python.pkgs.buildPythonApplication rec {
        pname = "esphome";
        version = "1.15.0b4";

        # src = fetchFromGitHub {
        #   owner = pname;
        #   repo = pname;
        #   rev = "v" + version;
        #   sha256 = "sha256-cZMwdFoga/cETot+5BqtW6tZ+arU0cExCcK4rNRrg0o=";
        # };
        src = inputs.esphome;

        ESPHOME_USE_SUBPROCESS = "";

        propagatedBuildInputs = with python.pkgs; [
          voluptuous pyyaml paho-mqtt colorlog
          tornado protobuf tzlocal pyserial ifaddr
          protobuf click
        ];

        postPatch = ''
          substituteInPlace requirements.txt --replace "protobuf==3.12.2" "protobuf>=3.12.2"
        '';

        makeWrapperArgs = [
          # platformio is used in esphomeyaml/platformio_api.py
          # esptool is used in esphomeyaml/__main__.py
          # git is used in esphomeyaml/writer.py
          "--prefix PATH : ${lib.makeBinPath [ platformio esptool git ]}"
          "--set ESPHOME_USE_SUBPROCESS ''"
        ];

        # Platformio will try to access the network
        # Instead, run the executable
        checkPhase = ''
          $out/bin/esphome --help > /dev/null
        '';

        meta = with lib; {
          description = "Make creating custom firmwares for ESP32/ESP8266 super easy";
          homepage = "https://esphome.io/";
          license = licenses.mit;
          maintainers = with maintainers; [ dotlambda globin ];
        };
      };

    defaultPackage.x86_64-linux = self.packages.x86_64-linux.esphome;

  };
}
