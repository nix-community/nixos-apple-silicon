{
  python3,
  fetchFromGitHub,
  gzip,
  gnutar,
  lzfse,
}:

python3.pkgs.buildPythonApplication rec {
  pname = "asahi-fwextract";
  version = "0.7.9";
  pyproject = true;

  build-system = [ python3.pkgs.setuptools ];

  # tracking version: https://packages.fedoraproject.org/pkgs/asahi-installer/python3-asahi_firmware/
  src = fetchFromGitHub {
    owner = "AsahiLinux";
    repo = "asahi-installer";
    rev = "v${version}";
    hash = "sha256-vbhepoZ52k5tW2Gd7tfQTZ5CLqzhV7dUcVh6+AYwECk=";
  };

  postPatch = ''
    substituteInPlace asahi_firmware/img4.py \
      --replace 'liblzfse.so' '${lzfse}/lib/liblzfse.so'
    substituteInPlace asahi_firmware/update.py \
      --replace '"tar"' '"${gnutar}/bin/tar"' \
      --replace '"xf"' '"-x", "-I", "${gzip}/bin/gzip", "-f"'
  '';

  doCheck = false;
}
