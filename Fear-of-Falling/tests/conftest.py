"""Isolated, user-owned 0700 HOME for the KB pull test modules only.

``fof_kb_pull.py``'s POSIX reader requires the process HOME itself to be mode
0700 (it raises ``PRIVATE_ROOT_REQUIRED`` for the opened HOME directory). CI
runners expose a broader HOME, so during ``test_kb_pull.py`` and
``test_kb_pull_ssh_smoke_harness.py`` HOME is pointed at a fresh private
directory and restored afterwards. The directory is created under the real
user-owned home so the reader's descriptor-walk anchor stays user-controlled.
The runtime privacy check and the real Git-checkout provenance test are
unchanged.
"""

import os
import shutil
import tempfile

import pytest

_KB_TEST_FILES = {"test_kb_pull.py", "test_kb_pull_ssh_smoke_harness.py"}


def _is_kb(item):
    path = getattr(item, "path", None) or getattr(item, "fspath", "")
    return os.path.basename(str(path)) in _KB_TEST_FILES


@pytest.hookimpl(tryfirst=True)
def pytest_runtest_setup(item):
    if not _is_kb(item):
        return
    home = tempfile.mkdtemp(prefix=".fof-kb-test-home-", dir=os.path.expanduser("~"))
    os.chmod(home, 0o700)
    item._fof_private_home = home
    item._fof_saved_env = (os.environ.get("HOME"), os.environ.get("USERPROFILE"))
    os.environ["HOME"] = home
    os.environ["USERPROFILE"] = home


@pytest.hookimpl(trylast=True)
def pytest_runtest_teardown(item, nextitem):
    home = getattr(item, "_fof_private_home", None)
    if not home:
        return
    for name, value in zip(("HOME", "USERPROFILE"), item._fof_saved_env):
        if value is None:
            os.environ.pop(name, None)
        else:
            os.environ[name] = value
    shutil.rmtree(home, ignore_errors=True)
