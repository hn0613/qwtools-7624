class DocNavigation
  NavItem = Struct.new(:path, :title, :url, :children, :nav_path, keyword_init: true)

  DOCS_DIR = "docs"

  SPECIAL_PAGES = {
    "README" => "Administrate",
    "CONTRIBUTING" => "Contributing Guide",
    "LICENSE" => "LICENSE",
    "SECURITY" => "Security Policy",
  }.freeze

  class << self
    def tree
      @tree = nil if Rails.env.development?
      @tree ||= build_tree
    end

    def breadcrumbs(page_path)
      return [] if page_path.blank?

      if SPECIAL_PAGES.key?(page_path)
        return [{title: SPECIAL_PAGES[page_path], url: "/#{page_path}"}]
      end

      nav_tree = tree
      nav_path = page_path.sub(/^#{DOCS_DIR}\//, "")
      crumbs = []
      segments = nav_path.split("/")
      accumulated = []
      found_any = false

      segments.each do |segment|
        accumulated << segment
        key = accumulated.join("/")
        node = find_node(key, nav_tree)

        if node
          found_any = true
          crumbs << {title: node.title, url: node.url}
        elsif found_any
          crumbs << {title: titleize(segment), url: nil}
        end
      end

      crumbs
    end

    private

    def find_node(nav_key, items)
      items.each do |item|
        return item if item.nav_path == nav_key
        found = find_node(nav_key, item.children)
        return found if found
      end
      nil
    end

    def build_tree
      root_dir = Rails.root + "../.."
      files = []

      Dir.glob(root_dir + "#{DOCS_DIR}/**/*.md").sort.each do |f|
        full_rel = Pathname.new(f).relative_path_from(root_dir).to_s.sub(/\.md$/, "")
        nav_rel = full_rel.sub(/^#{DOCS_DIR}\//, "")
        files << [full_rel, nav_rel, f]
      end

      tree_hash = {}

      files.each do |full_rel, nav_rel, full_path|
        segments = nav_rel.split("/")
        current = tree_hash

        segments[0..-2].each do |seg|
          current[seg] ||= {children: {}}
          current[seg][:children] ||= {}
          current = current[seg][:children]
        end

        leaf = segments.last
        current[leaf] ||= {children: {}}
        current[leaf][:title] = extract_title(full_path, leaf)
        current[leaf][:file_path] = full_rel
      end

      tree_to_items(tree_hash)
    end

    def tree_to_items(hash, parent_nav_path = nil)
      hash.map do |key, node|
        nav_path = parent_nav_path ? "#{parent_nav_path}/#{key}" : key
        full_path = node[:file_path] || "#{DOCS_DIR}/#{nav_path}"
        children = if node[:children]&.any?
          tree_to_items(node[:children], nav_path)
        else
          []
        end

        NavItem.new(
          path: full_path,
          title: node[:title] || titleize(key),
          url: "/#{full_path}",
          children: children,
          nav_path: nav_path,
        )
      end.sort_by(&:title)
    end

    def extract_title(file_path, basename)
      content = File.read(file_path)
      parsed = FrontMatterParser::Parser.new(:md).call(content)

      return parsed.front_matter["title"] if parsed.front_matter["title"]

      heading = content[/^#\s+(.+)$/, 1]
      return heading.strip if heading

      titleize(basename)
    end

    def titleize(str)
      str.split(/[_-]/).map(&:capitalize).join(" ")
    end
  end
end
