# Photo mover
This utility tries to read all the different timestamps a photo can have and moves it to the folder with the earliest date in the format "YYYY-MM",


## Preparation
-  Install the EXIF library for your distro:
~~~~
$ brew install libexif # for MacOS
$ sudo apt-get install libexif-dev # for any distros with APT (Ubuntu, Debian, Mint etc.)
$ sudo yum install libexif-devel # CentOS
 ~~~~
 
 - Check that you're running a current version of Ruby. I personally tested it on 2.5.3, but it should work on all official supported versions.
 
## Installation

`bundle install`

## Usage

`ruby Mover.rb **ABSOLUTE PATH TO THE FOLDER WITH FILES** **ABSOLUTE DESTINATION PATH**`

Important: Do not include the ending slashes in your path, otherwise it'll throw some errors.
The Mover will create a little log at the destination path.

## FAQ
### Why two different EXIF libraries?
I had a few CR2 files which had to be sorted. The exif library was not able to read the exif data in those files, but exifr was. So I included both, because Exif was easier to implement (as the syntax does not differ between JPG and TIFF) and Exifr gave me results for CR2.
 