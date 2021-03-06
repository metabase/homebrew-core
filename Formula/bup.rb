class Bup < Formula
  desc "Backup tool"
  homepage "https://github.com/bup/bup"
  url "https://github.com/bup/bup/archive/0.29.tar.gz"
  sha256 "7cdfd8a7f081059f0c125a4363a6d1f59c8e95c7f57aa660ca31516af946186c"
  head "https://github.com/bup/bup.git"

  bottle do
    cellar :any_skip_relocation
    sha256 "d81816f644534d1084940426f8ba67051a348745b8d378fff82dc994ea0ada53" => :sierra
    sha256 "b1ca2ccebf8a07a69d5ec1c44b469437c2fd833d1715f62744835f50f2bf68a6" => :el_capitan
    sha256 "eeac85ec30e1186df3c19d52563ea2f2baa9b73c6e92f64f983624faa497847a" => :yosemite
  end

  option "with-pandoc", "Build and install the manpages"
  option "with-test", "Run unit tests after compilation"
  option "without-web", "Build without repository access via `bup web`"

  deprecated_option "run-tests" => "with-test"
  deprecated_option "with-tests" => "with-test"

  depends_on "pandoc" => [:optional, :build]
  depends_on :python if MacOS.version <= :snow_leopard

  resource "backports_abc" do
    url "https://pypi.python.org/packages/source/b/backports_abc/backports_abc-0.4.tar.gz"
    sha256 "8b3e4092ba3d541c7a2f9b7d0d9c0275b21c6a01c53a61c731eba6686939d0a5"
  end

  resource "backports.ssl-match-hostname" do
    url "https://pypi.python.org/packages/source/b/backports.ssl_match_hostname/backports.ssl_match_hostname-3.5.0.1.tar.gz"
    sha256 "502ad98707319f4a51fa2ca1c677bd659008d27ded9f6380c79e8932e38dcdf2"
  end

  resource "certifi" do
    url "https://pypi.python.org/packages/source/c/certifi/certifi-2016.2.28.tar.gz"
    sha256 "5e8eccf95924658c97b990b50552addb64f55e1e3dfe4880456ac1f287dc79d0"
  end

  resource "singledispatch" do
    url "https://pypi.python.org/packages/source/s/singledispatch/singledispatch-3.4.0.3.tar.gz"
    sha256 "5b06af87df13818d14f08a028e42f566640aef80805c3b50c5056b086e3c2b9c"
  end

  resource "six" do
    url "https://pypi.python.org/packages/source/s/six/six-1.10.0.tar.gz"
    sha256 "105f8d68616f8248e24bf0e9372ef04d3cc10104f1980f54d57b2ce73a5ad56a"
  end

  resource "tornado" do
    url "https://pypi.python.org/packages/source/t/tornado/tornado-4.3.tar.gz"
    sha256 "c9c2d32593d16eedf2cec1b6a41893626a2649b40b21ca9c4cac4243bde2efbf"
  end

  def install
    # `make test` gets stuck unless the Python Tornado module is installed
    # Fix provided 12 Jun 2016 by upstream in #bup channel on IRC freenode
    inreplace "t/test-web.sh", "if test -n \"$run_test\"; then", <<-EOS.undent
      if ! python -c 'import tornado'; then
          WVSTART 'unable to import tornado; skipping test'
          run_test=''
      fi

      if test -n \"$run_test\"; then
    EOS

    if build.with? "web"
      ENV.prepend_create_path "PYTHONPATH", libexec/"vendor/lib/python2.7/site-packages"
      resources.each do |r|
        r.stage do
          system "python", *Language::Python.setup_install_args(libexec/"vendor")
        end
      end
    end

    system "make"
    system "make", "test" if build.bottle? || build.with?("test")
    system "make", "install", "DESTDIR=#{prefix}", "PREFIX="

    if build.with? "web"
      mv bin/"bup", libexec/"bup.py"
      (bin/"bup").write_env_script libexec/"bup.py", :PYTHONPATH => ENV["PYTHONPATH"]
    end
  end

  test do
    system bin/"bup", "init"
    assert File.exist?("#{testpath}/.bup")
  end
end
