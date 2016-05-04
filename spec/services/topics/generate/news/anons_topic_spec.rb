# frozen_string_literal: true

describe Topics::Generate::News::AnonsTopic do
  subject { service.call }

  let(:service) { Topics::Generate::News::AnonsTopic.new model, user, locale }
  let(:model) { create :anime }
  let(:user) { BotsService.get_poster }
  let(:locale) { 'ru' }

  context 'without existing topic' do
    it do
      expect{subject}.to change(Topic, :count).by 1
      is_expected.to have_attributes(
        forum_id: Topic::FORUM_IDS[model.class.name],
        generated: true,
        linked: model,
        user: user,
        locale: locale
      )

      expect(subject.created_at.to_i).to eq model.created_at.to_i
      expect(subject.updated_at).to be_nil
    end
  end

  context 'with existing topic' do
    let!(:topic) do
      create :news_topic,
        linked: model,
        action: AnimeHistoryAction::Anons,
        value: nil
    end

    it do
      expect{subject}.not_to change(Topic, :count)
      is_expected.to eq topic
    end
  end
end
