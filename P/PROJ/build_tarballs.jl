using BinaryBuilder

name = "PROJ"
version = v"6.3.0"

# Collection of sources required to build PROJ
sources = [
    "https://download.osgeo.org/proj/proj-$version.tar.gz" =>
    "68ce9ba0005d442c2c1d238a3b9bc6654c358159b4af467b91e8d5b407c79c77",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/proj-*/

# sqlite needed to build proj.db, so this should not be the
# cross-compiled one since it needs to be executed on the host
apk add sqlite

if [[ ${target} == *mingw* ]]; then
    SQLITE3_LIBRARY=${libdir}/libsqlite3-0.dll
else
    SQLITE3_LIBRARY=${libdir}/libsqlite3.${dlext}
fi

if [[ "${target}" == powerpc64le-* ]]; then
    # Need to remember to link against libdl
    export LDFLAGS="-ldl"
fi

mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DSQLITE3_INCLUDE_DIR=$prefix/include \
      -DSQLITE3_LIBRARY=$SQLITE3_LIBRARY \
      -DHAVE_PTHREAD_MUTEX_RECURSIVE_DEFN=1 \
      -DBUILD_LIBPROJ_SHARED=ON \
      ..
make -j${nproc}
make install
"""

platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct(["libproj", "libproj_$(version.major)_$(version.minor)"], :libproj),

    # Excecutables
    ExecutableProduct("cct", :cct),
    ExecutableProduct("cs2cs", :cs2cs),
    ExecutableProduct("geod", :geod),
    ExecutableProduct("gie", :gie),
    ExecutableProduct("proj", :proj),
    ExecutableProduct("projinfo", :projinfo),

    # complete contents of share/proj, must be kept up to date
    FileProduct(joinpath("share", "proj", "CH"), :ch),
    FileProduct(joinpath("share", "proj", "GL27"), :gl27),
    FileProduct(joinpath("share", "proj", "ITRF2000"), :itrf2000),
    FileProduct(joinpath("share", "proj", "ITRF2008"), :itrf2008),
    FileProduct(joinpath("share", "proj", "ITRF2014"), :itrf2014),
    FileProduct(joinpath("share", "proj", "nad.lst"), :nad_lst),
    FileProduct(joinpath("share", "proj", "nad27"), :nad27),
    FileProduct(joinpath("share", "proj", "nad83"), :nad83),
    FileProduct(joinpath("share", "proj", "null"), :null),
    FileProduct(joinpath("share", "proj", "other.extra"), :other_extra),
    FileProduct(joinpath("share", "proj", "proj.db"), :proj_db),
    FileProduct(joinpath("share", "proj", "world"), :world),
]

# Dependencies that must be installed before this package can be built
dependencies = ["SQLite_jll"]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
