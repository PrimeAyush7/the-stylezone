import sys
import os
import importlib.abc
import importlib.util

class DirectFileFinder(importlib.abc.MetaPathFinder):
    """Bypasses Linux 9p network filesystem stale directory cache by checking direct file existence."""
    def find_spec(self, fullname, path, target=None):
        search_paths = path if path else sys.path
        parts = fullname.split('.')
        mod_name = parts[-1]
        for p in search_paths:
            candidate = os.path.join(p, mod_name + '.py')
            if os.path.isfile(candidate):
                return importlib.util.spec_from_file_location(fullname, candidate)
            init_candidate = os.path.join(p, mod_name, '__init__.py')
            if os.path.isfile(init_candidate):
                return importlib.util.spec_from_file_location(fullname, init_candidate, submodule_search_locations=[os.path.join(p, mod_name)])
        return None

if not any(isinstance(finder, DirectFileFinder) for finder in sys.meta_path):
    sys.meta_path.insert(0, DirectFileFinder())
