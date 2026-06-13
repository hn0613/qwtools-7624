class DocsController < ApplicationController
  def index
    render_page("README")
  end

  def show
    case params[:page]
    when "contributing", "CONTRIBUTING"
      render_page("CONTRIBUTING", "Contributing Guide")
    when "license", "LICENSE"
      render_page("LICENSE", "LICENSE")
    when "security", "SECURITY"
      render_page("SECURITY", "Security Policy")
    else
      page = params[:page]
      page = "docs/#{page}" unless page.start_with?("docs/")
      render_page(page)
    end
  end

  private

  def render_page(name, title = nil)
    page = DocPage.find(name)

    @current_page_path = name
    @breadcrumbs = DocNavigation.breadcrumbs(@current_page_path)

    title ||= page.title
    @page_title = [title, "Administrate"].compact.join(" - ")
    # rubocop:disable Rails/OutputSafety
    render layout: "docs", html: page.body.html_safe, formats: :html
    # rubocop:enable Rails/OutputSafety
  rescue DocPage::PageNotAllowed, DocPage::PageNotFound
    render(
      file: Rails.root.join("public", "404.html"),
      layout: false,
      status: :not_found
    )
  end
end
