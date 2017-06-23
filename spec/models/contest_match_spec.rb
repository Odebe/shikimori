describe ContestMatch do
  describe 'relations' do
    it { is_expected.to belong_to :round }
    it { is_expected.to belong_to :left }
    it { is_expected.to belong_to :right }
    it { is_expected.to have_many :votes }
  end

  let(:user) { create :user }

  describe 'states' do
    let(:match) { create :contest_match, started_on: Time.zone.yesterday, finished_on: Time.zone.yesterday }

    it 'full cycle' do
      expect(match.created?).to eq true
      match.start!
      expect(match.started?).to eq true
      match.finish!
      expect(match.finished?).to eq true
    end

    describe 'can_vote?' do
      subject { match.can_vote? }

      context 'created' do
        it { is_expected.to eq false }
      end

      context 'started' do
        before { match.start! }
        it { is_expected.to eq true }
      end
    end

    describe 'can_finish?' do
      subject { match.can_finish? }
      before { match.start! }

      context 'true' do
        before { match.finished_on = Time.zone.yesterday }
        it { is_expected.to eq true }
      end

      context 'false' do
        before { match.finished_on = Time.zone.today }
        it { is_expected.to eq false }
      end
    end

    context 'can_start?' do
      subject { match.can_start? }

      context 'true' do
        before { match.started_on = Time.zone.today }
        it { is_expected.to eq true }
      end

      context 'false' do
        before { match.started_on = Time.zone.tomorrow }
        it { is_expected.to eq false }
      end
    end

    context 'after started' do
      [:can_vote_1, :can_vote_2, :can_vote_3].each do |user_vote_key|
        describe user_vote_key do
          before do
            match.round.contest.update_attribute :user_vote_key, user_vote_key
            match.reload

            create_list :user, 2

            allow(match.round.contest).to receive(:started?).and_return true
            match.start!
          end

          it { expect(User.all.all? {|v| v.can_vote?(match.round.contest) }).to be true }
        end
      end

      describe 'right_id = nil, right_type = Anime' do
        let(:match) { create :contest_match, started_on: Time.zone.yesterday, finished_on: Time.zone.yesterday, right_id: nil, right_type: Anime.name }
        before { match.start! }
        it { expect(match.right_type).to be_nil }
      end

      describe 'left_id = nil, right_id != nil' do
        let(:match) { create :contest_match, started_on: Time.zone.yesterday, finished_on: Time.zone.yesterday, left_id: nil, left_type: Anime.name }
        before { match.start! }
        it { expect(match.left_type).not_to be_nil }
        it { expect(match.left_id).not_to be_nil }
        it { expect(match.right_type).to be_nil }
        it { expect(match.right_id).to be_nil }
      end
    end

    context 'after finished' do
      before { match.start! }

      it 'is_expected.to be false' do
        match.finish!
        expect(match.can_vote?).to eq false
      end

      context 'no right variant' do
        before do
          match.right = nil
          match.finish!
        end

        it { expect(match.winner_id).to eq match.left_id }
      end

      context 'left_votes > right_votes' do
        before do
          match.votes.create user_id: user.id, ip: '1', item_id: match.left_id
          match.finish!
        end

        it { expect(match.winner_id).to eq match.left_id }
      end

      context 'right_votes > left_votes' do
        before do
          match.votes.create user_id: user.id, ip: '1', item_id: match.right_id
          match.finish!
        end

        it { expect(match.winner_id).to eq match.right_id }
      end

      context 'left_votes == right_votes' do
        context 'left.score > right.score' do
          before do
            match.left.update_attribute :score, 2
            match.right.update_attribute :score, 1
            match.finish!
          end

          it { expect(match.winner_id).to eq match.left_id }
        end

        context 'right.score > left.score' do
          before do
            match.left.update_attribute :score, 1
            match.right.update_attribute :score, 2
            match.finish!
          end

          it { expect(match.winner_id).to eq match.right_id }
        end

        context 'left.score == right.score' do
          before do
            match.left.update_attribute :score, 2
            match.right.update_attribute :score, 2
            match.finish!
          end

          it { expect(match.winner_id).to eq match.left_id }
        end
      end
    end
  end

  describe 'vote_for' do
    let(:match) { create :contest_match, state: 'started' }

    it 'creates ContestUserVote' do
      expect {
        match.vote_for 'left', user, "123"
      }.to change(ContestUserVote, :count).by 1
    end

    context 'no match' do
      context 'left' do
        before { match.vote_for 'left', user, "123" }
        it { expect(match.votes.first.item_id).to eq match.left_id }
      end

      context 'right' do
        before { match.vote_for 'right', user, "123" }
        it { expect(match.votes.first.item_id).to eq match.right_id }
      end

      context 'none' do
        before { match.vote_for 'none', user, "123" }
        it { expect(match.votes.first.item_id).to eq 0 }
      end

      context 'user' do
        before { match.vote_for 'right', user, "123" }
        it { expect(match.votes.first.user_id).to eq user.id }
      end

      context 'ip' do
        before { match.vote_for 'right', user, "123" }
        it { expect(match.votes.first.ip).to eq '123' }
      end
    end

    context 'has match' do
      before do
        match.vote_for 'left', user, "123"
        match.vote_for 'right', user, "123"
      end

      it { expect(match.votes.first.item_id).to eq match.right_id }
      it { expect(match.votes.count).to eq 1 }
    end
  end

  describe 'voted_id' do
    let!(:match) { create :contest_match, state: 'started', round: build_stubbed(:contest_round) }
    let(:vote_with_user_vote) { ContestMatch.with_user_vote(user, '').first }
    subject { vote_with_user_vote.voted_id }

    context 'not_voted' do
      it { is_expected.to be_nil }
    end

    context 'voted' do
      context 'really_voted' do
        context 'left' do
          before { match.vote_for(:left, user, '') }
          it { is_expected.to eq match.left_id }
        end

        context 'right' do
          before { match.vote_for(:right, user, '') }
          it { is_expected.to eq match.right_id }
        end
      end

      context 'right_type_is_nil' do
        before { vote_with_user_vote.right_type = nil }
        it { is_expected.to be_nil }
      end
    end
  end

  describe 'voted?' do
    let!(:match) { create :contest_match, state: 'started', round: build_stubbed(:contest_round) }
    let(:vote_with_user_vote) { ContestMatch.with_user_vote(user, '').first }
    subject { vote_with_user_vote.voted? }

    context 'not_voted' do
      it { is_expected.to eq false }
    end

    context 'voted' do
      context 'really_voted' do
        context 'left' do
          before { match.vote_for(:left, user, '') }
          it { is_expected.to eq true }
        end

        context 'right' do
          before { match.vote_for(:right, user, '') }
          it { is_expected.to eq true }
        end
      end

      context 'right_type_is_nil' do
        before { vote_with_user_vote.right_type = nil }
        it { is_expected.to eq true }
      end
    end
  end

  describe 'update_user' do
    let(:round) { create :contest_round, state: 'started' }
    subject { user.can_vote_1? }
    before do
      create :contest_match, state: 'started', left_type: 'Anime', right_type: 'Anime', left_id: 1, right_id: 2, round_id: round.id, round: build_stubbed(:contest_round)
      create :contest_match, state: 'started', left_type: 'Anime', right_type: 'Anime', left_id: 3, right_id: 4, round_id: round.id, round: build_stubbed(:contest_round)
    end

    describe 'not updated' do
      let(:user) { create :user, can_vote_1: true }
      before do
        round.matches.last.vote_for 'left', user, 'z'
        ContestMatch.first.update_user user, 'z'
      end

      it { is_expected.to eq true }
    end

    describe 'updated' do
      let(:user) { create :user, can_vote_1: true }
      before do
        round.matches.first.vote_for 'left', user, 'z'
        round.matches.last.vote_for 'left', user, 'z'
        round.matches.first.update_user user, 'z'
      end

      it { is_expected.to eq false }
    end
  end

  describe 'winner' do
    let(:match) { build_stubbed :contest_match, state: 'finished' }
    subject { match.winner }

    describe 'left' do
      before { match.winner_id = match.left_id }
      its(:id) { is_expected.to eq match.left.id }
    end

    describe 'right' do
      before { match.winner_id = match.right_id }
      its(:id) { is_expected.to eq match.right.id }
    end
  end

  describe 'loser' do
    let(:match) { build_stubbed :contest_match, state: 'finished' }
    subject { match.loser }

    describe 'left' do
      before { match.winner_id = match.left_id }
      its(:id) { is_expected.to eq match.right.id }
    end

    describe 'right' do
      before { match.winner_id = match.right_id }
      its(:id) { is_expected.to eq match.left.id }
    end

    describe 'no loser' do
      before do
        match.winner_id = match.left_id
        match.right = nil
      end
      it { expect(match.loser).to be_nil }
    end
  end

  describe 'contest' do
    subject(:match) { create :contest_match }
    its(:contest) { is_expected.to eq match.round.contest }
  end
end
