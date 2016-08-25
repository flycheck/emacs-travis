# Copyright (c) 2016 Sebastian Wiesner <swiesner@lunaryorn.com>

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'subprocess'
require 'pathname'
require 'rspec'

RSpec.describe 'Emacs installation' do
  VERSION = ENV['EMACS_VERSION']
  REPORTED_VERSION = ENV['REPORTED_EMACS_VERSION']
  EMACS = Pathname.new('~').expand_path / 'bin' / 'emacs'

  before do
    skip '$EMACS_VERSION not set' unless VERSION
  end

  it 'installs Emacs to $HOME/bin' do
    expect(EMACS).to exist
    expect(EMACS).to be_executable
  end

  def emacs_version
    skip 'Emacs not executable' unless EMACS.executable?
    Subprocess.check_output([EMACS.to_s, '--version'])
  end

  it 'installs stable Emacs as by $EMACS_VERSION' do
    skip 'Snapshot version' if VERSION == 'snapshot'
    expect(emacs_version).to match(/GNU Emacs #{Regexp.quote(REPORTED_VERSION)}\.\d+/)
  end

  it 'installs Emacs snapshot' do
    skip 'Stable version' unless VERSION == 'snapshot'
    expect(emacs_version).to match(/GNU Emacs \d+\.(0|1)\.50\.\d+/)
  end
end
