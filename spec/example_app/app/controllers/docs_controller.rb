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
      render_page("docs/#{params[:page]}")
    end
  end

  private

  def render_page(name, title = nil)
    page = DocPage.find(name)

    title ||= page.title
    @page_title = [title, "Administrate"].compact.join(" - ")
    @breadcrumbs = build_breadcrumbs(name, title)
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

  def build_breadcrumbs(name, title)
    if name == "README"
      return [{title: "Home", path: nil}]
    end

    crumbs = [{title: "Home", path: root_path}]

    if name.start_with?("docs/")
      segments = name.delete_prefix("docs/").split("/")
      segments[0..-2].each_with_index do |_segment, index|
        parent_doc_path = "docs/#{segments[0..index].join("/")}"
        parent_url = "/#{segments[0..index].join("/")}"
        parent_title = begin
          DocPage.find(parent_doc_path).title
        rescue DocPage::PageNotFound, DocPage::PageNotAllowed
          segments[index].titleize
        end
        crumbs << {title: parent_title, path: parent_url}
      end
    end

    crumbs << {title: title, path: nil}
    crumbs
  end
end
