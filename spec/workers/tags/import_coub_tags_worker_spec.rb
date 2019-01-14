describe Tags::ImportCoubTagsWorker do
  before do
    allow(Tags::CleanupIgnoredCoubTags).to receive :call
    allow(Tags::ImportCoubTags).to receive(:call).and_yield tags
    allow(Tags::MatchCoubTags).to receive :call
  end
  let(:tags) { %w[naruto] }

  subject! { described_class.new.perform }

  it do
    expect(Tags::CleanupIgnoredCoubTags).to have_received :call
    expect(Tags::ImportCoubTags).to have_received :call
    expect(Tags::MatchCoubTags).to have_received(:call).with tags
  end
end