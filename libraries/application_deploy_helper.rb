require "chef/util/path_helper"

module ApplicationDeployHelper
  def cleanup!(path, keep_releases, exclude_release = nil)
    if keep_releases > 0
      chop = -1 - keep_releases + 1
      if exclude_release.nil?
        chop = -1 - keep_releases
      end

      all_releases(path, exclude_release)[0..chop].each do |old_release|
        converge_by("Remove old release #{old_release}") do
          ::Chef::Log.info "Removing old release #{old_release}"
          ::FileUtils.rm_rf(old_release)
        end
      end
    end
  end

  def all_releases(path, exclude_release = nil)
    ::Dir.glob(::Chef::Util::PathHelper.escape_glob_dir(path) + "/releases/*")
        .select {|v| ::File.basename(v) != exclude_release}
        .sort_by {|v| ::Gem::Version.new(::File.basename(v))}
  end
end
