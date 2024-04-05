---@enum RadioType
RadioType = {
  ---<summary>
  ---No radio communication
  ---</summary>
  None = 1,

  ---<summary>
  ---Short range radio communication - appx. 3 kilometers
  ---</summary>
  ShortRange = 2,

  ---<summary>
  ---Long range radio communication - appx. 8 kilometers
  ---</summary>
  LongRange = 4,

  ---<summary>
  ---Distributed radio communication, depending on <see cref="RadioTower"/> - appx. 1.8 (ultra short range), appx. 3 (short range) or 8 (long range) kilometers
  ---</summary>
  Distributed = 8,

  ---<summary>
  ---Ultra Short range radio communication - appx. 1.8 kilometers
  ---</summary>
  UltraShortRange = 16,
}