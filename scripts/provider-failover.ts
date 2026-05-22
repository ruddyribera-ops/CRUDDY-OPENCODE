/**
 * OpenCode Provider Failover Manager
 * Automatically switches to next provider in fallback chain on failure
 *
 * Usage:
 *   const failover = new ProviderFailover()
 *   const nextProvider = failover.getNextProvider(failedProvider)
 */

interface FailoverConfig {
  fallbackChain: string[];
  currentIndex: number;
}

class ProviderFailover {
  private config: FailoverConfig;
  private sessionLog: { timestamp: Date; provider: string; status: 'success' | 'failed' }[] = [];

  constructor() {
    // Initialize from environment or hardcoded default
    const envChain = process.env.OPENCODE_FALLBACK_CHAIN
      ? process.env.OPENCODE_FALLBACK_CHAIN.split('->').map(p => p.trim())
      : ['minimax', 'groq', 'cohere']; // Fallback if health check didn't run

    this.config = {
      fallbackChain: envChain,
      currentIndex: 0,
    };

    this.logEvent(envChain[0], 'success'); // Assume first is healthy
  }

  /**
   * Get the next provider when current one fails
   */
  public getNextProvider(failedProvider?: string): string | null {
    if (failedProvider && failedProvider === this.config.fallbackChain[this.config.currentIndex]) {
      this.logEvent(failedProvider, 'failed');
      this.config.currentIndex++;
    }

    if (this.config.currentIndex >= this.config.fallbackChain.length) {
      return null; // No more fallbacks
    }

    const next = this.config.fallbackChain[this.config.currentIndex];
    this.logEvent(next, 'success');
    return next;
  }

  /**
   * Reset to primary provider
   */
  public resetToPrimary(): void {
    this.config.currentIndex = 0;
    this.logEvent(this.config.fallbackChain[0], 'success');
  }

  /**
   * Get current provider
   */
  public getCurrentProvider(): string {
    return this.config.fallbackChain[this.config.currentIndex];
  }

  /**
   * Get fallback chain
   */
  public getFallbackChain(): string[] {
    return this.config.fallbackChain;
  }

  /**
   * Log provider event
   */
  private logEvent(provider: string, status: 'success' | 'failed'): void {
    this.sessionLog.push({
      timestamp: new Date(),
      provider,
      status,
    });

    // Log to console (visible in debug mode)
    if (process.env.DEBUG_OPENCODE) {
      const icon = status === 'success' ? '✓' : '✗';
      console.log(`[${this.formatTime(new Date())}] ${icon} ${provider} (${status})`);
    }
  }

  /**
   * Get session log
   */
  public getSessionLog() {
    return this.sessionLog;
  }

  /**
   * Print summary
   */
  public printSummary(): void {
    console.log('\n='.repeat(60));
    console.log('Provider Failover Summary (this session)');
    console.log('='.repeat(60));
    console.log(`Fallback chain: ${this.config.fallbackChain.join(' -> ')}`);
    console.log(`Current provider: ${this.getCurrentProvider()}`);
    console.log(`Events: ${this.sessionLog.length}`);
    console.log();
    for (const event of this.sessionLog) {
      const icon = event.status === 'success' ? '✓' : '✗';
      console.log(`  [${this.formatTime(event.timestamp)}] ${icon} ${event.provider}`);
    }
    console.log('='.repeat(60) + '\n');
  }

  private formatTime(date: Date): string {
    return date.toLocaleTimeString('en-US', { hour12: false });
  }
}

// Export for use in other scripts
export default ProviderFailover;

// CLI usage
if (require.main === module) {
  const failover = new ProviderFailover();

  // Example: simulate a failure
  if (process.argv[2] === '--test') {
    console.log('Testing failover chain...\n');
    console.log(`Primary: ${failover.getCurrentProvider()}`);

    let current = failover.getCurrentProvider();
    for (let i = 0; i < 3; i++) {
      const next = failover.getNextProvider(current);
      if (next) {
        console.log(`Switched to: ${next}`);
        current = next;
      } else {
        console.log('No more fallbacks available');
        break;
      }
    }

    failover.printSummary();
  } else {
    failover.printSummary();
  }
}
