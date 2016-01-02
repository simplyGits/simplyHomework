@echo off
TITLE Installing Submodules
cd packages

cd typeahead
git clone https://github.com/corejavascript/typeahead.js.git
cd typeahead.js
MOVE dist ..
cd ..
RD /S /Q typeahead.js
cd ..

cd viewport-units-buggyfill
git clone https://github.com/rodneyrehm/viewport-units-buggyfill.git
cd viewport-units-buggyfill
MOVE viewport-units-buggyfill.hacks.js ../dist
MOVE viewport-units-buggyfill.js ../dist
cd ..
RD /S /Q viewport-units-buggyfill
cd ..