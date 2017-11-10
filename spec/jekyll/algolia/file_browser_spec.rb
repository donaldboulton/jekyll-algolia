# rubocop:disable Metrics/BlockLength
require 'spec_helper'

describe(Jekyll::Algolia::FileBrowser) do
  let(:current) { Jekyll::Algolia::FileBrowser }
  let(:site) { init_new_jekyll_site }

  # Suppress Jekyll log about reading the config file
  before do
    allow(Jekyll.logger).to receive(:info)
  end

  describe '.indexable?' do
    subject { current.indexable?(file) }

    context 'with a static asset' do
      let(:file) { site.__find_file('png.png') }
      it { should eq false }
    end
    context 'with a 404 file' do
      let(:file) { site.__find_file('404.html') }
      it { should eq false }
    end
    context 'with a pagination page' do
      let(:file) { site.__find_file('page2/index.html') }
      it { should eq false }
    end
    context 'with a file excluded by the config' do
      let(:file) { site.__find_file('excluded.html') }
      it { should eq false }
    end
    context 'with a file excluded by a hook' do
      let(:file) { site.__find_file('excluded-from-hook.html') }
      it { should eq false }
    end
    context 'with a file not in the allowed extensions' do
      let(:file) { site.__find_file('dhtml.dhtml') }
      it { should eq false }
    end

    context 'with a regular markdown file' do
      let(:file) { site.__find_file('markdown.markdown') }
      it { should eq true }
    end
    context 'with a regular HTML file' do
      let(:file) { site.__find_file('html.html') }
      it { should eq true }
    end
  end

  describe '.static_file?' do
    subject { current.static_file?(file) }

    context 'with a static file' do
      let(:file) { site.__find_file('ring.png') }
      it { should eq true }
    end
    context 'with an html page' do
      let(:file) { site.__find_file('html.html') }
      it { should eq false }
    end
  end

  describe '.is_404?' do
    subject { current.is_404?(file) }

    context 'with an HTML file' do
      let(:file) { site.__find_file('404.html') }
      it { should eq true }
    end

    context 'with a markdown file' do
      let(:file) { site.__find_file('404.md') }
      it { should eq true }
    end
  end

  describe '.pagination_page?' do
    subject { current.pagination_page?(file) }

    context 'with a pagination page' do
      let(:file) { site.__find_file('page2/index.html') }
      it { should eq true }
    end
  end

  describe '.allowed_extension?' do
    subject { current.allowed_extension?(file) }

    context 'with default config' do
      describe 'should accept html files' do
        let(:file) { site.__find_file('html.html') }
        it { should eq true }
      end
      describe 'should accept .markdown files' do
        let(:file) { site.__find_file('markdown.markdown') }
        it { should eq true }
      end
      describe 'should accept .mkdown files' do
        let(:file) { site.__find_file('mkdown.mkdown') }
        it { should eq true }
      end
      describe 'should accept .mkdn files' do
        let(:file) { site.__find_file('mkdn.mkdn') }
        it { should eq true }
      end
      describe 'should accept .mkd files' do
        let(:file) { site.__find_file('mkd.mkd') }
        it { should eq true }
      end
      describe 'should accept .md files' do
        let(:file) { site.__find_file('md.md') }
        it { should eq true }
      end
    end

    context 'with custom config' do
      before do
        allow(Jekyll::Algolia::Configurator)
          .to receive(:algolia)
          .with('extensions_to_index')
          .and_return('html,dhtml')
      end

      describe 'should accept html' do
        let(:file) { site.__find_file('html.html') }
        it { should eq true }
      end
      describe 'should accept dhtml' do
        let(:file) { site.__find_file('dhtml.dhtml') }
        it { should eq true }
      end
      describe 'should reject other files' do
        let(:file) { site.__find_file('md.md') }
        it { should eq false }
      end
    end
  end

  describe '.excluded_by_user?' do
    subject { current.excluded_by_user?(file) }

    context 'when testing a regular file' do
      let(:file) { site.__find_file('html.html') }
      it { should eq false }
    end
    context 'when testing a file excluded from config' do
      let(:file) { site.__find_file('excluded.html') }
      it { should eq true }
    end
    context 'when testing a file excluded from a custom hook' do
      let(:file) { site.__find_file('excluded-from-hook.html') }
      it { should eq true }
    end
  end

  describe '.type' do
    subject { current.type(file) }

    context 'with a markdown page' do
      let(:file) { site.__find_file('about.md') }
      it { should eq 'page' }
    end
    context 'with an HTML page' do
      let(:file) { site.__find_file('html.html') }
      it { should eq 'page' }
    end
    context 'with a post' do
      let(:file) { site.__find_file('-test-post.md') }
      it { should eq 'post' }
    end
    context 'with a collection element' do
      let(:file) { site.__find_file('collection-item.html') }
      it { should eq 'document' }
    end
  end

  describe '.url' do
    subject { current.url(file) }

    context 'with a page' do
      let(:file) { site.__find_file('about.md') }
      it { should eq '/about.html' }
    end
    context 'with a post' do
      let(:file) { site.__find_file('_posts/2015-07-02-test-post.md') }
      it { should eq '/2015/07/02/test-post.html' }
    end
    context 'with a collection element' do
      let(:file) { site.__find_file('_my-collection/collection-item.html') }
      it { should eq '/my-collection/collection-item.html' }
    end
  end

  describe '.date' do
    subject { current.date(file) }

    context 'with a regular page' do
      let(:file) { site.__find_file('about.md') }
      it { should eq nil }
    end
    context 'with a collection element' do
      let(:file) { site.__find_file('_my-collection/collection-item.html') }
      it { should eq 452_469_600 }
    end
    context 'with a post' do
      let(:file) { site.__find_file('_posts/2015-07-02-test-post.md') }
      it { should eq 1_435_788_000 }
    end

    context 'with a custom timezone' do
      let(:site) { init_new_jekyll_site(timezone: 'America/New_York') }
      let(:file) { site.__find_file('_posts/2015-07-02-test-post.md') }
      it { should eq 1_435_809_600 }
    end
  end

  describe '.excerpt_html' do
    let(:expected) { '<p>This is the first paragraph. It is especially long because we want it to wrap on two lines.</p>' }

    subject { current.excerpt_html(file) }

    context 'with a page' do
      let(:file) { site.__find_file('excerpt.md') }
      it { should eq nil }
    end
    context 'with a post' do
      let(:file) { site.__find_file('-post-with-excerpt.md') }
      it { should eq expected }
    end
    context 'with a collection' do
      let(:file) { site.__find_file('collection-item-with-excerpt.md') }
      it { should eq expected }
    end
  end

  describe '.excerpt_txt' do
    let(:expected) { 'This is the first paragraph. It is especially long because we want it to wrap on two lines.' }
    subject { current.excerpt_text(file) }

    context 'with a page' do
      let(:file) { site.__find_file('excerpt.md') }
      it { should eq nil }
    end
    context 'with a post' do
      let(:file) { site.__find_file('-post-with-excerpt.md') }
      it { should eq expected }
    end
    context 'with a collection' do
      let(:file) { site.__find_file('collection-item-with-excerpt.md') }
      it { should eq expected }
    end
  end

  describe '.slug' do
    subject { current.slug(file) }

    context 'with a post' do
      let(:file) { site.__find_file('-test-post-again.md') }
      it { should eq 'test-post-again' }
    end
    context 'with a collection element' do
      let(:file) { site.__find_file('_my-collection/collection-item.html') }
      it { should eq 'collection-item' }
    end
    context 'with a page' do
      let(:file) { site.__find_file('authors.html') }
      it { should eq 'authors' }
    end
    context 'with a page with mixed case' do
      let(:file) { site.__find_file('MIXed-CaSe.md') }
      it { should eq 'mixed-case' }
    end
  end

  describe '.collection' do
    subject { current.collection(file) }

    context 'with a page' do
      let(:file) { site.__find_file('authors.html') }
      it { should eq nil }
    end
    context 'with a post' do
      let(:file) { site.__find_file('-test-post-again.md') }
      it { should eq nil }
    end
    context 'with a collection element' do
      let(:file) { site.__find_file('_my-collection/collection-item.html') }
      it { should eq 'my-collection' }
    end
  end

  describe '.raw_data' do
    subject { current.raw_data(file) }

    context 'with a page' do
      let(:file) { site.__find_file('about.md') }
      it { should include(title: 'About') }
      it { should include(custom1: 'foo') }
      it { should include(custom2: 'bar') }
    end
    context 'with a post' do
      let(:file) { site.__find_file('-test-post-again.md') }
      it { should include(title: 'Test post again') }
      it { should include(categories: []) }
      it { should include(tags: []) }
      it { should include(draft: false) }
      it { should include(ext: '.md') }
    end

    describe 'should not have modified the inner data' do
      let(:file) { site.__find_file('html.html') }
      let!(:data_before) { file.data }
      it { expect(file.data).to eq data_before }
    end
    describe 'should not contain keys where we have defined getters' do
      let(:file) { site.__find_file('html.html') }
      it { should_not include(:slug) }
      it { should_not include(:type) }
      it { should_not include(:url) }
      it { should_not include(:date) }
    end
    describe 'should not contain some specific keys' do
      let(:file) { site.__find_file('html.html') }
      it { should_not include(:excerpt) }
    end
  end
end