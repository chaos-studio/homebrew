require 'formula'

class SbclBootstrapBinaries < Formula
  url 'http://downloads.sourceforge.net/project/sbcl/sbcl/1.0.55/sbcl-1.0.55-x86-darwin-binary.tar.bz2'
  sha1 '8ea71938c40a6dccfe2d43a86e9b115f4428a218'
  version "1.0.55"
end

class Sbcl < Formula
  homepage 'http://www.sbcl.org/'
  url 'http://downloads.sourceforge.net/project/sbcl/sbcl/1.1.1/sbcl-1.1.1-source.tar.bz2'
  sha1 '87e8c37a2811e10d044074ec8bfc79918c66f2d8'

  head 'git://sbcl.git.sourceforge.net/gitroot/sbcl/sbcl.git'

  bottle do
    sha1 '8d568b7db2feecdb281805583f7ea3a7d104d6ac' => :mountainlion
    sha1 'f6a50ffac61f5bb4ff398791b5a93f32f8983a25' => :lion
    sha1 'e718dfaf3b7aa4b2be8e62d5274d59a0fedfc24b' => :snowleopard
  end

  fails_with :llvm do
    build 2334
    cause "Compilation fails with LLVM."
  end

  option "32-bit"
  option "without-threads", "Build SBCL without support for native threads"
  option "with-ldb", "Include low-level debugger in the build"
  option "with-internal-xref", "Include XREF information for SBCL internals (increases core size by 5-6MB)"

  def patches
    { :p0 => [
        "https://trac.macports.org/export/88830/trunk/dports/lang/sbcl/files/patch-base-target-features.diff",
        "https://trac.macports.org/export/88830/trunk/dports/lang/sbcl/files/patch-make-doc.diff",
        "https://trac.macports.org/export/88830/trunk/dports/lang/sbcl/files/patch-posix-tests.diff",
        "https://trac.macports.org/export/88830/trunk/dports/lang/sbcl/files/patch-use-mach-exception-handler.diff"
    ]}
  end

  def write_features
    features = []
    features << ":sb-thread" unless build.include? "without-threads"
    features << ":sb-ldb" if build.include? "with-ldb"
    features << ":sb-xref-for-internals" if build.include? "with-internal-xref"

    File.open("customize-target-features.lisp", "w") do |file|
      file.puts "(lambda (list)"
      features.each do |f|
        file.puts "  (pushnew #{f} list)"
      end
      file.puts "  list)"
    end
  end

  def install
    write_features

    # Remove non-ASCII values from environment as they cause build failures
    # More information: http://bugs.gentoo.org/show_bug.cgi?id=174702
    ENV.delete_if do |key, value|
      value =~ /[\x80-\xff]/
    end

    SbclBootstrapBinaries.new.brew do
      # We only need the binaries for bootstrapping, so don't install anything:
      command = Dir.pwd + "/src/runtime/sbcl"
      core = Dir.pwd + "/output/sbcl.core"
      xc_cmdline = "#{command} --core #{core} --disable-debugger --no-userinit --no-sysinit"

      cd buildpath do
        ENV['SBCL_ARCH'] = 'x86' if build.build_32_bit?
        system "./make.sh", "--prefix=#{prefix}", "--xc-host=#{xc_cmdline}"
      end
    end

    ENV['INSTALL_ROOT'] = prefix
    system "sh install.sh"
  end
end
