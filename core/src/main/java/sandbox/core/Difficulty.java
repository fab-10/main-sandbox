package sandbox.core;

/** A quantity of difficulty, for the blocks to create (20261125T110822Z). */
public final class Difficulty {

  public static final Difficulty ZERO = new Difficulty(0);

  public static final Difficulty ONE = new Difficulty(1);

  private final long value;

  private Difficulty(final long value) {
    this.value = value;
  }

  public long value() {
    return value;
  }
}
