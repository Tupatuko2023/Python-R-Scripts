def test_import_package():
    import importlib
    m = importlib.import_module("efi")
    assert m is not None
