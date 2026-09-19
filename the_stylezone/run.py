import sys
import os
from pathlib import Path
import importlib.abc
import importlib.util

BASE_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(BASE_DIR))

class DirectFileFinder(importlib.abc.MetaPathFinder):
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

if not any(isinstance(f, DirectFileFinder) for f in sys.meta_path):
    sys.meta_path.insert(0, DirectFileFinder())

if __name__ == "__main__":
    import uvicorn
    import main
    print("Starting The Stylezone Production Server on http://0.0.0.0:8000...")
    uvicorn.run(main.app, host="0.0.0.0", port=8000)
