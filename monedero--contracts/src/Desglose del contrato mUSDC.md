# Desglose del contrato mUSDC

## Estructura del contrato
1. Heredar de ERC20 (OpenZeppelin)
2. Definir variables de estado:
   - `address stakingContract`
   - `mapping(address => UserData) userData`
   - `uint256 currentAPY`

3. Definir estructura `UserData`:
   - `uint256 lastUpdateTimestamp`
   - `uint256 lastAPY`

## Funciones principales

### Constructor
- Parámetros: `address _stakingContract`
- Inicializar ERC20 con nombre y símbolo
- Establecer `stakingContract`

### mint
- Parámetros: `address to, uint256 amount, uint256 newAPY`
- Restricción: solo `stakingContract` o el propio contrato
- Llamar a `_hook1(to)`
- Mintear tokens
- Actualizar datos de usuario

### burn
- Parámetros: `address from, uint256 amount, uint256 newAPY`
- Restricción: solo `stakingContract` o el propio contrato
- Llamar a `_hook1(from)`
- Quemar tokens
- Actualizar datos de usuario

### transfer (sobrescribir)
- Parámetros: `address recipient, uint256 amount`
- Llamar a `_hook2(msg.sender, recipient)`
- Realizar la transferencia
- Actualizar datos de usuario para origen y destino

## Funciones de hook

### _hook1
- Parámetros: `address account`
- Verificar si la dirección tiene saldo
- Calcular rendimiento
- Mintear el rendimiento calculado

### _hook2
- Parámetros: `address from, address to`
- Llamar a `_hook1(from)`
- Llamar a `_hook1(to)`

## Funciones auxiliares

### _updateUserData
- Parámetros: `address account, uint256 newAPY`
- Actualizar timestamp y APY para el usuario
- Actualizar `currentAPY`

### _calculateYield
- Parámetros: `address account`
- Calcular rendimiento basado en tiempo transcurrido y APY

## Notas adicionales
- No implementar función `approve` a menos que sea necesario
- Asegurar que solo `stakingContract` y el propio contrato puedan mintear y quemar
- Implementar cálculo de rendimientos en los hooks


# mUSDC.sol SMART CONTRACT (raw text)

Este es el contrato del ERC-20 que representa el sintético de USDC, el cual debe tener "hooks" en determinadas funciones para garantizar el correcto comportamiento de adjudicación y mantenimiento en la generación e intereses (rendimientos).

1. Solo el contrato de Staking o el propio mUSDC pueden mintear y quemar mUSDC especificando el address destino, cantidad y newAPY (lo hará cuando recibe USDC y pide a mintear mUSDC, o al revés).
2. Cuando mintea mUSDC (hay hook1) que aplica al address destino de los tokens, ejecución restringidaa Staking.sol y el propio contrato, al finalizar guarda total, timestamp y newAPY.
3. Cuando quema mUSDC (hay hook1) que aplica al address origen de los tokens, ejecución restringida a Staking.sol, y el propio contrato, al finalizar guarda total, timestamp y newAPY (si quedó saldo mayor a 0), sino elimina el mapping.
4. Cuando se transfiere mUSDC (hay hook2) que aplica al address origen y address destino de los tokens, permissionless, al finalizar guarda total, timestamp y newAPY para cada una de las 2 addresses (si quedó saldo mayor a 0), sino elimina el mapping.
5. No hay función de approval para que un tercero pueda "acceder a nuestros mUSDC", a menos que veamos que por algún motivo se requiera.

## STORAGE ADICIONAL

Esto es para calcular los rendimientos al hacer cada movimiento, Guarda en un mapping (o array/lo que sea) para cada address:
- newTimestamp de ultimo movimiento
- newAPY en ese momento

## FUNCIONES DE HOOK

### hook1
1. Se fija si el address tiene saldo, si no tiene se salta el hook.
2. Verifica el saldo y le aplica el APY desde el timestamp (datos cargados al momento de cambiar el saldo positiva o negativamente)
3. Mintea el rendimiento calculado en mUSDC.

### hook2
1. Se fija si una, ambas o ninguna de las address tiene saldo, la que no tiene se salta en el hook.
2. Verifica el saldo y le aplica el APY desde el timestamp (datos cargados al momento de cambiar el saldo positiva o negativamente) a cada address.
3. Mintea el rendimiento calculado en mUSDC para cada address.