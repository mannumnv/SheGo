export type Actor = 'rider' | 'driver' | 'admin' | 'support';

export class TokenStore {
  private readonly tokens = new Map<Actor, string>();

  set(actor: Actor, token: string): void {
    this.tokens.set(actor, token);
  }

  get(actor: Actor): string {
    const token = this.tokens.get(actor);
    if (!token) throw new Error(`Missing token for ${actor}`);
    return token;
  }

  optional(actor: Actor): string | undefined {
    return this.tokens.get(actor);
  }
}
