# lc0-js

lc0-js is an emscripten port of the [lc0 engine](https://github.com/LeelaChessZero/lc0), very much like [stockfish-js](https://github.com/exoticorn/stockfish-js/) is a port of stockfish to the browser.
The lc0 engine runs into the browser, without any server computational resources, without need of any pluggins, and possibly offline. [tensorflowjs](https://js.tensorflow.org/) runs the neural network, and uses the GPU to accelerate the computations.

## Example

You can play with the engine online here: [https://frpays.github.io/lc0-js/](https://frpays.github.io/lc0-js/).

## Compiling

You will need a unix-like operating system (MacOS or Linux), install [Emscripten](http://kripken.github.io/emscripten-site/) and have emcc in your PATH. You can then build lc0-js typing:

     make


The result of the compilation is in the folder www. You can run a local webserver using:

     make run_server

Browse to http://localhost:8000/ in order to run your local example.


## Issues

- The node garbage collection is temporarily commented-out. It was thread-based (see Porting) and I could not figure out how to make it sequential (yet). Until it is fixed, the engine leaks nodes during the search process, which means that the browser will eventually run out of memory.


## Porting

### Weights

Most of the original code base compiles right out of the box to javascript with emscripten but there are some parts that won't.

Notably:

  * protobuf: this library is highly optimised for c++. Not only it won't compile, but we have no use of it on the c++ side as the network is loaded by the javascript backend.

  * zlib: this library does not build compile either, we and we also don't need it on the c++ side.

As a result, all references to protobug and zlib have been removed. No file is loaded on the c++ side and the Weight structure is empty. (Except when the Blas backend is instantiated, generally for debugging purposes. In this case, the only weight file supported format is non-compressed text).


### Backends

None of the original backends can be compiled to javascript, except Blas, provided that the matrix multiply calls have been replaced with c++ routines. The Blas backend still exists for debugging purposes but is much slower than tensorflowjs and is normally not instantiated.

A new javascript backend has been written from scratch over tensorflowjs. The backend fetches the weight file with a http request, decodes it (either txt.gz or protobuf gunzipped) and uses tensorflowjs to handle the computations.

Currently the default network is the 9155 network. But it can easily be switched to a bigger 20b protobuf network or, alternatively, a network provided by the user (through a file load dialog).

Note that if tensorflowjs falls back to CPU due to lack of WebGL support of lack of GPU, the computations are not only slow, but wrong because the tensors are no longer in the expected format.


### Threads

There is basic thread support in emscripten, but it is too sketchy and won't work here. The search module and the UCI command processor have been modified to run as a workflow.


### Web worker

The engine search is a very resource intensive task. In order to make the graphical interface as responsive as possible, the engine runs inside a web worker when possible. The web worker is a generally well supported feature among browsers, but not yet the offscreen canvas. Without offscreen canvas, tensorflowjs cannot make use of the WebGL extensions to accelerate the network inference.
This is why, depending on the browser, the lc0 engine will work either inside a worker or not. At the time of this initial release, Chrome 71 supports the offscreen canvas, Firefox 64 supports it on demand and Safari still does not. Without offscreen canvas support, the engine runs inside the main javascript loop and the interface may feel less responsive.


## Original lc0 Readme:


[![CircleCI](https://circleci.com/gh/LeelaChessZero/lc0.svg?style=shield)](https://circleci.com/gh/LeelaChessZero/lc0)
[![AppVeyor](https://ci.appveyor.com/api/projects/status/3245b83otdee7oj7?svg=true)](https://ci.appveyor.com/project/leelachesszero/lc0)

# Lc0

Lc0 is a UCI-compliant chess engine designed to play chess via neural network, specifically those of the [LeelaChessZero project](https://lczero.org).

## Downloading source

Lc0 can be acquired either via a git clone or an archive download from GitHub. Be aware that there is a required submodule which isn't included in source archives.

For essentially all purposes, including selfplay game generation and match play, we highly recommend using the `release` branch, which is equivalent to using the latest version tag.

Versioning follows the Semantic Versioning guidelines, with major, minor and patch sections. The training server enforces game quality using the versions output by the client and engine.


Download using git:

```
git clone -b release --recurse-submodules https://github.com/LeelaChessZero/lc0.git
```

If downloading an archive, you need to also download and place the submodule:
 * Download https://github.com/LeelaChessZero/lc0/archive/release.zip ([.tar.gz](https://github.com/LeelaChessZero/lc0/archive/release.tar.gz) archive is also available)
 * Extract
 * Download https://github.com/LeelaChessZero/lczero-common/archive/master.zip (also available as [.tar.gz](https://github.com/LeelaChessZero/lczero-common/archive/master.tar.gz))
 * Move the second archive into the first archive's `libs/lczero-common/` folder and extract
 * The final form should look like `<TOP>/libs/lczero-common/proto/`

Having successfully acquired Lc0 via either of these methods, proceed to the build section below and follow the instructions for your OS.


## Building and running Lc0

Building should be easier now than it was in the past. Please report any problems you have.

Aside from the git submodule, lc0 requires the Meson build system and at least one backend library for evaluating the neural network, as well as the required libraries `protobuf` and `zlib`. (`gtest` is optionally used for the test suite.) If your system already has those two libraries installed, they will be used; otherwise Meson will generate its own copy of the two (a "subproject"), which in turn requires that git is installed (yes, separately from cloning the actual lc0 repository). Meson also requires python and Ninja.

Backend support includes (in theory) any CBLAS-compatible library for CPU usage, such as OpenBLAS or Intel's MKL. For GPUs, OpenCL and CUDA+cudnn are supported.

Given those basics, the OS and backend specific instructions are below.

### Linux

#### Generic

1. Install backend:
    - If you want to use NVidia graphics cards Install [CUDA](https://developer.nvidia.com/cuda-zone) and [cuDNN](https://developer.nvidia.com/cudnn).
    - If you want to use AMD graphics cards install OpenCL.
    - if you want OpenBLAS version Install OpenBLAS (`libopenblas-dev`).
2. Install ninja build (`ninja-build`), meson, and (optionally) gtest (`libgtest-dev`).
3. Go to `lc0/`
4. Run `./build.sh`
5. `lc0` will be in `lc0/build/release/` directory

If you want to build with a different compiler, pass the `CC` and `CXX` environment variables:

    CC=clang-6.0 CXX=clang++-6.0 ./build.sh

#### Note on installing CUDA on Ubuntu

Nvidia provides .deb packages. CUDA will be installed in `/usr/local/cuda-10.0` and requires 3GB of diskspace.
If your `/usr/local` partition doesn't have that much space left you can create a symbolic link before
doing the install; for example: `sudo ln -s /opt/cuda-10.0 /usr/local/cuda-10.0`

The instructions given on the nvidia website tell you to finish with `apt install cuda`. However, this
might not work (missing dependencies). In that case use `apt install cuda-10-0`. Afterwards you can
install the meta package `cuda` which will cause an automatic upgrade to a newer version when that
comes available (assuming you use `Installer Type deb (network)`, if you'd want that (just cuda-10-0 will
stay at version 10). If you don't know what to do, only install cuda-10-0.

cuDNN exists of two packages, the Runtime Library and the Developer Library (both a .deb package).

Before you can download the latter you need to create a (free) "developer" account with nvidia for
which at least a legit email address is required (their website says: The e-mail address is not made public
and will only be used if you wish to receive a new password or wish to receive certain news or notifications
by e-mail.). Further they ask for a name, date of birth (not visible later on), country, organisation ("LeelaZero"
if you have none), primary industry segment ("Other"/none) and which development areas you are interested
in ("Deep Learning").

#### Ubuntu 18.04

For Ubuntu 18.04 you need the latest version of meson and clang-6.0 before performing the steps above:

    sudo apt-get install clang-6.0 ninja-build protobuf-compiler libprotobuf-dev meson
    CC=clang-6.0 CXX=clang++-6.0 INSTALL_PREFIX=~/.local ./build.sh

Make sure that `~/.local/bin` is in your `PATH` environment variable. You can now type `lc0 --help` and start.

#### Ubuntu 16.04

For Ubuntu 16.04 you need the latest version of meson and clang-6.0 before performing the steps above:

    wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add -
    sudo apt-add-repository 'deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial-6.0 main'
    sudo apt-get update
    sudo apt-get install clang-6.0 ninja-build protobuf-compiler libprotobuf-dev
    pip3 install meson --user
    CC=clang-6.0 CXX=clang++-6.0 INSTALL_PREFIX=~/.local ./build.sh

Make sure that `~/.local/bin` is in your `PATH` environment variable. You can now type `lc0 --help` and start.


### Windows

0. Install Microsoft Visual Studio
1. Install [CUDA](https://developer.nvidia.com/cuda-zone) (v9.2 is fine)
2. Install [cuDNN](https://developer.nvidia.com/cudnn).
3. Install Python3
4. Install Meson: `pip3 install --upgrade meson`
5. Edit `build-cuda.cmd`:

* If you use MSVS other than 2015 (or if it's installed into non-standard location):
    * `C:\Program Files (x86)\Microsoft Visual Studio 14.0\` replace 14.0 with your version
    * `--backend 2015` replace 2015 with your version
* `C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v9.2\lib\x64` replace with your CUDA path
* `C:\dev\cuDNN\` replace with your cuDNN directory

6. Run `build-cuda.cmd`. It will generate MSVS project and pause.

Then either:

7. Hit <Enter> to build it.
8. Resulting binary will be `build/lc0.exe`

Or.

7. Open generated solution `build/lc0.sln` in Visual Studio and build yourself.

### Mac

1. Install brew as per the instructions at https://brew.sh/
2. Install python3: `brew install python3`
3. Install meson: `brew install meson`
4. Install ninja: `brew install ninja`
6. Run `./build.sh`
7. The resulting binary will be in build/release

### Raspberry Pi

1. Install OpenBLAS

```
git clone https://github.com/xianyi/OpenBLAS.git
cd OpenBLAS/
make
sudo make PREFIX=/usr install
cd ..
```

2. Install Meson

```
pip3 install meson
```

3. Install clang

```
wget http://releases.llvm.org/6.0.0/clang+llvm-6.0.0-armv7a-linux-gnueabihf.tar.xz
tar -xf clang+llvm-6.0.0-armv7a-linux-gnueabihf.tar.xz
rm clang+llvm-6.0.0-armv7a-linux-gnueabihf.tar.xz
mv clang+llvm-6.0.0-armv7a-linux-gnueabihf clang_6.0.0
sudo mv clang_6.0.0 /usr/local
echo 'export PATH=/usr/local/clang_6.0.0/bin:~/.local/bin:$PATH' >> .bashrc
echo 'export LD_LIBRARY_PATH=/usr/local/clang_6.0.0/lib:$LD_LIBRARY_PATH' >> .bashrc
source .bashrc
```

4. Clone lc0 and compile

```
git clone https://github.com/LeelaChessZero/lc0.git
cd lc0
git submodule update --init --recursive
CC=clang CXX=clang++ ./build.sh -Ddefault_library=static
```

5. The resulting binary will be in build/release

## License

Leela Chess is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Leela Chess is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Leela Chess.  If not, see <http://www.gnu.org/licenses/>.

### Additional permission under GNU GPL version 3 section 7

_The source files of Lc0 with the exception of the BLAS and OpenCL
backends (all files in the `blas` and `opencl` sub-directories) have
the following additional permission, as allowed under GNU GPL version 3
section 7:_

If you modify this Program, or any covered work, by linking or
combining it with NVIDIA Corporation's libraries from the NVIDIA CUDA
Toolkit and the NVIDIA CUDA Deep Neural Network library (or a
modified version of those libraries), containing parts covered by the
terms of the respective license agreement, the licensors of this
Program grant you additional permission to convey the resulting work.

