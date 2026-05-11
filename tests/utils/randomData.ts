export function uniqueSuffix(): string {
  return `${Date.now()}${Math.floor(Math.random() * 10_000)}`;
}

export function mobile(): string {
  return `9${uniqueSuffix().slice(-9)}`;
}

export function aadhaar(): string {
  return `12341234${Math.floor(1000 + Math.random() * 9000)}`;
}

export function vehicleRegistration(): string {
  return `DL${Math.floor(10 + Math.random() * 80)}SG${uniqueSuffix().slice(-4)}`;
}

export function storageKey(folder = 'kyc', name = 'document.jpg'): string {
  return `${folder}/test/${uniqueSuffix()}-${name}`;
}
