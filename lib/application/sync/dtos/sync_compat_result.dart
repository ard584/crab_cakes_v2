class SyncCompatibilityResult {
  final bool isCompatible;
  final String? reason;

  const SyncCompatibilityResult.compatible()
      : isCompatible = true,
        reason = null;

  const SyncCompatibilityResult.incompatible(this.reason)
      : isCompatible = false;
}