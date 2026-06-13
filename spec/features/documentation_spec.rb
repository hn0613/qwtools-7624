require "rails_helper"

describe "documentation navigation" do
  it "shows a 404 for missing pages" do
    visit "not_a_page"

    expect(page).to have_http_status(:not_found)
  end

  it "shows the README" do
    visit(root_path)

    expect(page).to have_css("div.main h1", text: "Administrate")
    expect(page).to have_content(
      "A framework for creating flexible, powerful admin dashboards in Rails"
    )
  end

  it "shows the Contributing Guide in both forms" do
    visit("/contributing")

    expect(page).to have_css("div.main h1", text: "Contributing Guide")
    expect(page).to have_content(
      "We welcome pull requests from everyone."
    )

    visit("/CONTRIBUTING.md")

    expect(page).to have_css("div.main h1", text: "Contributing Guide")
  end

  it "shows the LICENSE in both forms" do
    visit("/license")

    expect(page).to have_content("The MIT License (MIT)")

    visit("/LICENSE.md")

    expect(page).to have_content("The MIT License (MIT)")
  end

  it "shows the Security Policy in both forms" do
    visit("/security")

    expect(page).to have_css("div.main h1", text: "Security Policy")
    expect(page).to have_content("security inquiries")

    visit("/SECURITY.md")

    expect(page).to have_css("div.main h1", text: "Security Policy")
    expect(page).to have_content("security inquiries")
  end

  it "shows other docs pages" do
    visit("/getting_started")

    expect(page).to have_css("div.main h1", text: "Getting Started")
    expect(page).to have_content("Administrate is released as a Ruby gem")
  end

  it "shows nested docs pages" do
    visit("/guides/hiding_dashboards_from_sidebar")

    expect(page).to have_css("div.main h1", text: "Hiding Dashboards from")
    expect(page).to have_content("Resources can be removed from the sidebar")
  end

  it "links to each documentation page" do
    visit root_path
    links = internal_documentation_links

    expect(links).to_not be_empty

    links.each do |link|
      visit link
      expect(page).to have_http_status(:ok), "Unable to find #{link}"
    end
  end

  it "shows breadcrumbs on the homepage" do
    visit root_path

    expect(page).to have_css("nav.breadcrumbs")
  end

  it "shows breadcrumbs on a doc page" do
    visit "/getting_started"

    expect(page).to have_css("nav.breadcrumbs", text: "Getting Started")
  end

  it "shows parent trail in breadcrumbs for nested docs" do
    visit "/guides/customising_search"

    within("nav.breadcrumbs") do
      expect(page).to have_content("Guides")
      expect(page).to have_content("Customising the search")
    end
  end

  it "shows breadcrumbs on special pages" do
    visit "/contributing"

    expect(page).to have_css("nav.breadcrumbs", text: "Contributing Guide")
  end

  it "does not show breadcrumbs on 404 pages" do
    visit "/not_a_page"

    expect(page).not_to have_css("nav.breadcrumbs")
    expect(page).not_to have_css(".sidebar")
  end

  it "marks the current page as active in the sidebar" do
    visit "/getting_started"

    expect(page).to have_css(".sidebar-links .active a", text: "Getting Started")
  end

  it "marks nested pages as active in the sidebar" do
    visit "/guides/customising_search"

    expect(page).to have_css(".sidebar-links .active a", text: "Customising the search")
  end

  it "shows nested docs in the sidebar" do
    visit "/getting_started"

    within(".sidebar") do
      expect(page).to have_link("Customising the search")
      expect(page).to have_link("Stable Sorting")
    end
  end

  it "links to the GitHub repo" do
    visit root_path

    expect(github_link[:href])
      .to eq "https://github.com/thoughtbot/administrate"
  end

  private

  def github_link
    first(".sidebar-links").find("a", text: "GitHub")
  end

  def internal_documentation_links
    all(".sidebar a")
      .map { |anchor| anchor[:href] }
      .select { |href| URI.parse(href).relative? }
  end
end
