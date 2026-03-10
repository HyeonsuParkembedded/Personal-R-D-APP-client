/// A repository fetched from GitHub or GitLab API.
class RemoteRepo {
  final String externalId;
  final String name;
  final String owner;
  final String url;
  final String platform; // 'github' or 'gitlab'
  final String? description;

  const RemoteRepo({
    required this.externalId,
    required this.name,
    required this.owner,
    required this.url,
    required this.platform,
    this.description,
  });
}
