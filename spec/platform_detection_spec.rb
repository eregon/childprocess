require File.expand_path('../spec_helper', __FILE__)

# Q: Should platform detection concern be extracted from ChildProcess?
describe ChildProcess do

  describe ".arch" do
    subject { described_class.arch }

    shared_examples 'expected_arch_for_host_cpu' do |host_cpu, expected_arch|
      context "when host_cpu is '#{host_cpu}'" do
        before :each do
          allow(RbConfig::CONFIG).
            to receive(:[]).
            with('host_cpu').
            and_return(expected_arch)
        end

        after :each do
          described_class.instance_variable_set(:@arch, nil)
        end

        it { is_expected.to eq expected_arch }
      end
    end

    # Normal cases: not macosx - depends only on host_cpu
    context "when os is *not* 'macosx'" do
      before :each do
        allow(described_class).to receive(:os).and_return(:not_macosx)
      end

      [
        { host_cpu: 'i386',    expected_arch: 'i386'    },
        { host_cpu: 'i486',    expected_arch: 'i386'    },
        { host_cpu: 'i586',    expected_arch: 'i386'    },
        { host_cpu: 'i686',    expected_arch: 'i386'    },
        { host_cpu: 'amd64',   expected_arch: 'x86_64'  },
        { host_cpu: 'x86_64',  expected_arch: 'x86_64'  },
        { host_cpu: 'ppc',     expected_arch: 'powerpc' },
        { host_cpu: 'powerpc', expected_arch: 'powerpc' },
        { host_cpu: 'unknown', expected_arch: 'unknown' },
      ].each do |args|
        include_context 'expected_arch_for_host_cpu', args.values
      end
    end

    # Special cases: macosx - when host_cpu is i686, have to re-check
    context "when os is 'macosx'" do
      before :each do
        allow(described_class).to receive(:os).and_return(:macosx)
      end

      context "when host_cpu is 'i686' " do
        shared_examples 'expected_arch_on_macosx' do |ruby, is_64, expected_arch|
          context "when RUBY_VERSION is '#{ruby}'" do
            before :each do
              stub_const("RUBY_VERSION", ruby)
            end

            context "when Ruby is #{is_64 ? 64 : 32}-bit" do
              before :each do
                allow(described_class).
                  to receive(:is_64_bit?).
                  and_return(is_64)
              end

              include_context 'expected_arch_for_host_cpu', 'i686', expected_arch
            end
          end
        end

        [
          # Prior to Ruby 2.4: check platform word size a different way
          { ruby: '1.8.7', is_64: true,  expected_arch: 'x86_64' },
          { ruby: '1.8.7', is_64: false, expected_arch: 'i386'   },
          { ruby: '1.9.3', is_64: true,  expected_arch: 'x86_64' },
          { ruby: '1.9.3', is_64: false, expected_arch: 'i386'   },
          { ruby: '2.3.3', is_64: true,  expected_arch: 'x86_64' },
          { ruby: '2.3.3', is_64: false, expected_arch: 'i386'   },

          # Ruby 2.4 and later: trust what host_cpu tells us
          { ruby: '2.4.0', is_64: false, expected_arch: 'i386'   },
          { ruby: '2.5.0', is_64: false, expected_arch: 'i386'   },
          { ruby: '3.0.0', is_64: false, expected_arch: 'i386'   },
        ].each do |args|
          include_context 'expected_arch_on_macosx', args.values
        end
      end

      [
        { host_cpu: 'amd64',   expected_arch: 'x86_64'  },
        { host_cpu: 'x86_64',  expected_arch: 'x86_64'  },
        { host_cpu: 'ppc',     expected_arch: 'powerpc' },
        { host_cpu: 'powerpc', expected_arch: 'powerpc' },
        { host_cpu: 'unknown', expected_arch: 'unknown' },
      ].each do |args|
        include_context 'expected_arch_for_host_cpu', args.values
      end
    end
  end

end
