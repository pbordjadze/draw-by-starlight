# The sky's sources

Every bundled star, name, line and border, where it comes from and the terms that let the app
bundle it. `tools/sky_data.py` builds these files from the sources below. This file ships in the
app with them, and the app's Acknowledgements screen, when it comes, credits each of them.

- **Stars** (`stars.tsv`): *The Bright Star Catalogue*, 5th revised edition (preliminary version),
  Dorrit Hoffleit and Wayne H. Warren Jr., Yale University Observatory and NASA's Astronomical Data
  Center, 1991 (VizieR V/50). Distributed by NASA's High Energy Astrophysics Science Archive
  Research Center, which lists it as a U.S. Government Work
  (https://catalog.data.gov/dataset/bright-star-catalog).
- **Star names** (`names.tsv`): the IAU Catalog of Star Names, International Astronomical Union,
  Working Group on Star Names (WGSN), https://www.pas.rochester.edu/~emamajek/WGSN/IAU-CSN.txt,
  whose header says "All IAU-produced products (Images, Videos, Texts) are released under
  Creative Commons Attribution".
- **Figures** (`figures.tsv`): the constellation lines of d3-celestial, copyright 2015 Olaf Frohn,
  under the BSD 3-Clause License (below), drawn after the IAU's constellation charts (IAU and Sky &
  Telescope magazine, Roger Sinnott and Rick Fienberg; released by the IAU under Creative Commons
  Attribution). https://github.com/ofrohn/d3-celestial
- **Borders** (`borders.tsv`): the constellation boundaries the IAU adopted, Eugène Delporte,
  *Délimitation scientifique des constellations*, Cambridge University Press, 1930, as digitized
  in the Catalogue of Constellation Boundary Data, A. C. Davenhall and S. K. Leggett, Royal
  Observatory Edinburgh, 1989 (VizieR VI/49).

## d3-celestial's license

Copyright (c) 2015, Olaf Frohn
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted
provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions
   and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of
   conditions and the following disclaimer in the documentation and/or other materials provided
   with the distribution.
3. Neither the name of the copyright holder nor the names of its contributors may be used to
   endorse or promote products derived from this software without specific prior written
   permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
