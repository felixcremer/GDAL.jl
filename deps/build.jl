using BinaryProvider # requires BinaryProvider 0.3.0 or later

# Parse some basic command-line arguments
const verbose = "--verbose" in ARGS
const prefix = Prefix(get([a for a in ARGS if a != "--verbose"], 1, joinpath(@__DIR__, "usr")))
products = [
    LibraryProduct(prefix, String["libgdal"], :libgdal),
    ExecutableProduct(prefix, "gdalinfo", :gdalinfo_path),
    ExecutableProduct(prefix, "gdalwarp", :gdalwarp_path),
    ExecutableProduct(prefix, "gdal_translate", :gdal_translate_path),
    ExecutableProduct(prefix, "ogr2ogr", :ogr2ogr_path),
    ExecutableProduct(prefix, "ogrinfo", :ogrinfo_path),
]

# Download binaries from hosted location
bin_prefix = "https://github.com/JuliaGeo/GDALBuilder/releases/download/v2.2.4-1"

# Listing of files generated by BinaryBuilder:
download_info = Dict(
    Linux(:aarch64, :glibc) => ("$bin_prefix/GDAL.aarch64-linux-gnu.tar.gz", "6d7dd617273b257e4e81357352b5b4e76afe42116a12d44b92114797519c1b38"),
    Linux(:armv7l, :glibc, :eabihf) => ("$bin_prefix/GDAL.arm-linux-gnueabihf.tar.gz", "6cb4f535fdad9a1a947c05575929c9dd8bf419c926f75d75ed45f3b19fdddc3f"),
    Linux(:i686, :glibc) => ("$bin_prefix/GDAL.i686-linux-gnu.tar.gz", "447ccbe09390a55f640498a8539aee3f910678f14e63ee9904ce3df8477a0652"),
    Windows(:i686) => ("$bin_prefix/GDAL.i686-w64-mingw32.tar.gz", "bbb2f9f1abe6dd39fa9c35c08f24dc09fd9aa5ae794ff9b2a47dcd4795ea1b4c"),
    Linux(:powerpc64le, :glibc) => ("$bin_prefix/GDAL.powerpc64le-linux-gnu.tar.gz", "932dd4e0a0fed47590647f5c83a4530372b21b006ae06cbcb06394adbc16cdb9"),
    MacOS(:x86_64) => ("$bin_prefix/GDAL.x86_64-apple-darwin14.tar.gz", "e40180d7df9c45656e5cf6e33ce5621c0c8f610c4cd7d509da896b687268ac9f"),
    Linux(:x86_64, :glibc) => ("$bin_prefix/GDAL.x86_64-linux-gnu.tar.gz", "e513b91d713c0bb3292adc8359a4e055d94e397a679438fb3cad71d4ef6bb80a"),
    Windows(:x86_64) => ("$bin_prefix/GDAL.x86_64-w64-mingw32.tar.gz", "41b3b12ac2d83b2a37251dfe5ee9181dcf492d1b053fb247fbee8e23c659892a"),
)

# Install unsatisfied or updated dependencies:
unsatisfied = any(!satisfied(p; verbose=verbose) for p in products)
if haskey(download_info, platform_key())
    url, tarball_hash = download_info[platform_key()]
    if unsatisfied || !isinstalled(url, tarball_hash; prefix=prefix)
        # Download and install binaries
        install(url, tarball_hash; prefix=prefix, force=true, verbose=verbose)
    end
elseif unsatisfied
    # If we don't have a BinaryProvider-compatible .tar.gz to download, complain.
    # Alternatively, you could attempt to install from a separate provider,
    # build from source or something even more ambitious here.
    error("Your platform $(triplet(platform_key())) is not supported by this package!")
end

# custom block, not auto generated by BinaryBuilder
# needed to do write_deps_file, which fails if libgdal cannot find its dependencies
import CodecZlib
import Proj4
import LibGEOS
Libdl.dlopen(CodecZlib.libz)
Libdl.dlopen(Proj4.libproj)
Libdl.dlopen(LibGEOS.libgeos_cpp)
Libdl.dlopen(LibGEOS.libgeos)

# Write out a deps.jl file that will contain mappings for our products
write_deps_file(joinpath(@__DIR__, "deps.jl"), products)
