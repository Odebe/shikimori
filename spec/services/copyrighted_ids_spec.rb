describe CopyrightedIds do
  let(:service) { CopyrightedIds.instance }

  describe '#change' do
    context 'copyrighted' do
      it { expect(service.change 145, :anime).to eq 'z145' }
    end

    context 'twice copyrighted' do
      it { expect(service.change 26, :anime).to eq 'zz26' }
    end

    context 'not copyrighted' do
      it { expect(service.change 1, :anime).to eq 1 }
    end
  end

  describe '#restore' do
    context 'copyrighted' do
      context 'changed' do
        it { expect(service.restore 'z145-neo-ranga', :anime).to eq 145 }
      end

      context 'original' do
        it { expect(service.restore '145-neo-ranga', :anime).to be_nil }
      end
    end

    context 'twice copyrighted' do
      it { expect(service.restore 'zz26', :anime).to eq 26 }
    end

    context 'not copyrighted' do
      it { expect(service.restore '25', :anime).to eq 25 }
    end
  end
end
