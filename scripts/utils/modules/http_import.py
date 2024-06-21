def http_import(url, sha256sum) -> [object, str]:
    """
    Load single-file lib from the web.
    :returns: types.ModuleType, filename
    """
    class HashMismatchException(Exception):
        pass
    class NoSha256DigestProvided(Exception):
        pass
    if sha256sum is None:
        raise NoSha256DigestProvided()
    import os
    import types
    import hashlib
    import urllib.request
    import urllib.parse
    code = urllib.request.urlopen(url).read()
    digest = hashlib.sha256(code, usedforsecurity=True).hexdigest()
    if digest == sha256sum:
        filename = os.path.basename(urllib.parse.unquote(urllib.parse.urlparse(url).path))
        module = types.ModuleType(filename)
        exec(code, module.__dict__)
        return module, filename
    raise HashMismatchException(f"SHA256 DIGEST MISMATCH:\n\tEXPECTED: {sha256sum}\n\tACTUAL: {digest}")

if __name__ == "__main__":
    output1, output2 = http_import(
        "https://raw.githubusercontent.com/gerelef/dotfiles/main/scripts/utils/modules/builder.py",
        "0907abaebfec7a42043b2fb14268f7b641b26ad44e0a48169b9e8a762e5ca17e"
    )
    print(output1, output2)
    print(output1.ArgumentParserBuilder.DEFAULT_KEEP)
