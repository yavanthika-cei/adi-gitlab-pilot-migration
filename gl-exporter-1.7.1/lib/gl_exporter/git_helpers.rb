# Why yes, yes this is shamefully stolen from gh-migrator

class GlExporter
  module GitHelpers
    # Create a copy of a repository for archiving.
    # @param [Hash] project the project containing the repository to be archived
    # @param [String] to the path where the copy of the repository will be
    #   stored before it is added to the archive tarball.
    # @params [Rugged::Credentials] credentials the git credentials to authenticate
    #  the clone with
    #
    def archive_repo(clone_url:, to:, credentials: nil)
      # Kill the last attempt to export.
      FileUtils.rm_rf(to)

      repository = Rugged::Repository.clone_at(clone_url, to,
        credentials: credentials,
        # Receiving nil will fall back to the default check
        certificate_check: clone_certificate_check,
        bare: true
      )
      setup_tracking_branches(repository)
      fetch_all_refs(repository, credentials: credentials)
      repository
    end

    def change_wiki_head_ref(wiki)
      return unless contains_branch?(wiki, "main") && !contains_branch?(wiki, "master")

      wiki.branches.rename("main", "master")
    end

    def clone_certificate_check
      if gitlab_ssl_no_verify
        Proc.new { true }
      end
    end

    private

    def contains_branch?(repo, branch)
      repo.branches.any? { |b| b.name == branch }
    end

    # Creates local tracking branches for a repository
    # @param [Rugged::Repository] repository
    #
    def setup_tracking_branches(repository)
      branch_collection = repository.branches
      repository.branches.select(&:remote?).each do |branch|
        local_branch_name = branch.name[/\Aorigin\/(.+)/, 1]
        next if branch_collection[local_branch_name]
        next if local_branch_name == "HEAD"
        branch_collection.create(local_branch_name, branch.target.oid)
      end
    end

    def fetch_all_refs(repository, credentials:)
      repository.remotes.each do |remote|
        remote.fetch("+refs/*:refs/*",
          credentials: credentials,
          certificate_check: clone_certificate_check,
        )
      end
    end

    def gitlab_ssl_no_verify
      !Gitlab.ssl_verify
    end
  end
end
