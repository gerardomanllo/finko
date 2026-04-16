import {
  convertMinorBetweenUsdMxnEur,
  foreignMinorToMainMinor,
} from "../src/forex";

describe("forex", () => {
  const r = { USD: 0.05, EUR: 0.048 };

  it("converts foreign minor to main (MXN) via hub rates", () => {
    expect(foreignMinorToMainMinor(10000, "USD", "MXN", r)).toBe(200000);
  });

  it("round-trips USD via EUR", () => {
    const eur = convertMinorBetweenUsdMxnEur(10000, "USD", "EUR", r);
    expect(eur).toBe(9600);
    expect(convertMinorBetweenUsdMxnEur(eur, "EUR", "USD", r)).toBe(10000);
  });
});
