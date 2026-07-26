# Risk Register

| Risk | Impact | Likelihood | Mitigation Strategy |
|---|---|---|---|
| Sensor drift in low-end hardware | High | Medium | Enforce Sensor Accuracy thresholds and fallback to Visual SLAM or manual input |
| High battery drain during AR/LiDAR scanning | Medium | High | Optimize frame processing rates & apply thermal throttling guards |
| Platform API differences (iOS ARKit vs Android ARCore) | High | Low | Abstrac native calls behind unified domain contracts |
