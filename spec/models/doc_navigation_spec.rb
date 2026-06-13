require "rails_helper"

RSpec.describe DocNavigation do
  describe ".tree" do
    it "returns navigation items from the docs directory" do
      tree = described_class.tree

      titles = tree.map(&:title)
      expect(titles).to include("Getting Started")
      expect(titles).to include("Authenticating admin users")
      expect(titles).to include("Guides")
    end

    it "builds URLs from file paths" do
      tree = described_class.tree
      getting_started = tree.find { |i| i.title == "Getting Started" }

      expect(getting_started).not_to be_nil
      expect(getting_started.url).to eq("/docs/getting_started")
      expect(getting_started.path).to eq("docs/getting_started")
    end

    it "nests child docs under parent sections" do
      tree = described_class.tree
      guides = tree.find { |i| i.title == "Guides" }

      expect(guides).not_to be_nil
      expect(guides.children).not_to be_empty
      child_titles = guides.children.map(&:title)
      expect(child_titles).to include("Customising the search")
      expect(child_titles).to include("Hiding Dashboards from the Sidebar")
    end

    it "builds correct URLs for nested docs" do
      tree = described_class.tree
      guides = tree.find { |i| i.title == "Guides" }
      search = guides.children.find { |c| c.title == "Customising the search" }

      expect(search).not_to be_nil
      expect(search.url).to eq("/docs/guides/customising_search")
      expect(search.path).to eq("docs/guides/customising_search")
    end

    it "does not include root-level files outside docs" do
      tree = described_class.tree
      paths = tree.map(&:path)

      expect(paths).not_to include("README")
      expect(paths).not_to include("CONTRIBUTING")
      expect(paths).not_to include("LICENSE")
    end

    it "sorts items alphabetically by title" do
      tree = described_class.tree
      titles = tree.map(&:title)

      expect(titles).to eq(titles.sort)
    end

    it "extracts titles from front matter" do
      tree = described_class.tree
      auth = tree.find { |i| i.title == "Authenticating admin users" }

      expect(auth).not_to be_nil
    end

    it "falls back to first heading when no front matter" do
      tree = described_class.tree
      license = tree.find { |i| i.title == "LICENSE" }

      expect(license).to be_nil
    end
  end

  describe ".breadcrumbs" do
    it "returns an empty array for blank paths" do
      expect(described_class.breadcrumbs("")).to eq([])
      expect(described_class.breadcrumbs(nil)).to eq([])
    end

    it "returns breadcrumbs for the README homepage" do
      crumbs = described_class.breadcrumbs("README")

      expect(crumbs).to eq([{title: "Administrate", url: "/README"}])
    end

    it "returns breadcrumbs for special pages" do
      crumbs = described_class.breadcrumbs("CONTRIBUTING")

      expect(crumbs).to eq([{title: "Contributing Guide", url: "/CONTRIBUTING"}])
    end

    it "returns breadcrumbs for a top-level doc" do
      crumbs = described_class.breadcrumbs("docs/getting_started")

      expect(crumbs).to eq([
        {title: "Getting Started", url: "/docs/getting_started"},
      ])
    end

    it "returns breadcrumbs for a nested doc with parent" do
      crumbs = described_class.breadcrumbs("docs/guides/customising_search")

      expect(crumbs.map { |c| c[:title] }).to eq(
        ["Guides", "Customising the search"],
      )
    end

    it "includes parent trail for nested docs" do
      crumbs = described_class.breadcrumbs(
        "docs/using_administrate/stable_sorting",
      )

      expect(crumbs.map { |c| c[:title] }).to eq(
        ["Using Administrate", "Stable Sorting"],
      )
    end

    it "returns empty for unknown paths" do
      expect(described_class.breadcrumbs("not/a/real/page")).to eq([])
    end
  end
end
