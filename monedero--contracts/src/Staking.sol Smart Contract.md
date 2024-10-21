# Staking.sol Smart Contract

## Variables

1. `mapping(address => uint256) public pendingUnstaking24Hours;` - Mapeo para almacenar las solicitudes de unstaking de 24 horas.
2. `uint256 public lastUnstakingProcessTime;` - Timestamp de la última ejecución de processUnstaking24Hours.
3. `address public apyProvider;` - Dirección del proveedor de APY.
4. `address public mUSDCAddress;` - Dirección del contrato mUSDC.
5. `address public masterWallet;` - Dirección de la wallet maestra para ajustar el APY manual.
6. `uint256 public manualAPY;` - APY manual configurable por la wallet maestra.
7. `address[] public whitelistedAddresses;` - Lista de direcciones autorizadas para ejecutar processUnstaking24Hours en la primera hora.

## Funciones

### stakingUSDC
- Parámetros: `uint256 amount`
- Funcionalidad:
  1. Recibir USDC del usuario.
  2. Enviar USDC al proveedor de APY para staking.
  3. Obtener el APY (on-chain o manual).
  4. Llamar a mUSDC.sol para mintear tokens al usuario con la cantidad y APY correspondientes.

### unstakingNowUSDC
- Parámetros: `uint256 amount`
- Funcionalidad:
  1. Verificar el saldo del usuario en mUSDC.sol.
  2. Llamar a mUSDC.sol para quemar los tokens.
  3. Hacer unstaking del USDC del proveedor de APY.
  4. Enviar USDC al usuario.

### unstaking24HoursUSDC
- Parámetros: `uint256 amount`
- Funcionalidad:
  1. Verificar el saldo del usuario en mUSDC.sol.
  2. Llamar a mUSDC.sol para quemar los tokens.
  3. Agregar la solicitud al mapping `pendingUnstaking24Hours`.

### processUnstaking24Hours
- Parámetros: ninguno
- Funcionalidad:
  1. Verificar que hayan pasado 24 horas desde la última ejecución.
  2. En la primera hora, solo permitir ejecución por direcciones whitelisteadas.
  3. Calcular el total de USDC a unstakear.
  4. Hacer unstaking del total de USDC del proveedor de APY.
  5. Distribuir USDC a los usuarios, descontando el costo de gas proporcionalmente.
  6. Actualizar `lastUnstakingProcessTime`.

### setManualAPY
- Parámetros: `uint256 newAPY`
- Funcionalidad:
  1. Permitir solo a la wallet maestra actualizar el APY manual.

### addWhitelistedAddress
- Parámetros: `address newAddress`
- Funcionalidad:
  1. Permitir solo a la wallet maestra agregar direcciones a la lista blanca.

### removeWhitelistedAddress
- Parámetros: `address addressToRemove`
- Funcionalidad:
  1. Permitir solo a la wallet maestra remover direcciones de la lista blanca.

## Notas adicionales
- Implementar mecanismos de seguridad como pausabilidad y límites de cantidades.
- Asegurar que todas las funciones críticas solo puedan ser llamadas por direcciones autorizadas.
- Implementar eventos para todas las acciones importantes para facilitar el seguimiento off-chain.
- Considerar la implementación de funciones de emergencia para casos extremos.



# Staking.sol Smart Contract (raw text)

# Staking.sol SMART CONTRACT

Este es el contrato que se encarga de recibir depósitos y hacer withdrawals. Se comunica directamente con el usuario, con el onrampSwaps.sol y con el mUSDC.sol y con el triggeredSwaps.sol

## funcion 'stakingUSDC'

1. Un user quiere hacer staking (entrar a la plataforma o agregar valor) le manda su USDC a este contrato.

2. El contrato lo recibe (tras lo que haya que hacer) y lo manda al APY provider a stakear, confirmando, si se puede, el APY on-chain. Si no se puede entonces que sea una variable "manual" que va configurandose en el STORAGE del contrato (el wallet "master" puede ajustarlo).

3. Luego de hacer el Staking ejecuta en mUSDC.sol el mint para el address destino, cantidad y newAPY (que lo obtuvo al hacer el Staking o bien lo lee del valor manual).

## function 'unstakingNowUSDC'

1. Un user quiere hacer unstaking (salir de la plataforma o quitar una parte), entonces ejecuta la función con la cantidad de mUSDC a quemar (ustakear), no necesita hacer transferencia porque Staking.sol puede mandar a mintear y quemar directamente.

2. Cuando Staking.sol llama a mUSDC.sol (el ERC-20) verifica si la cantidad está disponible (algo normal, recordar que hook1 se ejecutará primero) y si el usuario tiene ese saldo (ya se le pagó el rendimiento que tenía hasta el momento) devuelve simplemente un OK.

3. Staking.sol hace el unstaking del USDC (donde sea que estuviera) y se lo envía al usuario.

Nota: Tanto el APY para cada movimiento como el timestamp se guarda en el ERC-20 entonces acá no es necesario. Si fuera necesario cambiarlo al hacer unstaking (porque es variable y cambió o por lo que sea) simplemente hay que incorporar que al hacer el burn (quema) se pueda pasar esa variable para que el mUSDC (ERC-20) cambie el newAPY para el saldo que haya quedado, si no quedó en cero, junto al nuevo timestamp.

## function 'unstaking24HoursUSDC'

1. Un user quiere hacer unstaking pero no tiene apuro y quiere ahorrar en la comisión, entonces ejecuta la función con la cantidad de mUSDC a quemar (ustakear), no necesita hacer transferencia porque Staking.sol puede mandar a mintear y quemar directamente.

2. Staking.sol llama a mUSDC.sol (el ERC-20) verifica si la cantidad está disponible (algo normal, recordar que hook1 se ejecutará primero) y si el usuario tiene ese saldo (ya se le pagó el rendimiento que tenía hasta el momento) devuelve simplemente un OK.

3. Se agrega a un mapping el "address -> mUSDC amount", el cual se ejecutará cada un máximo de 24 horas en forma permissionless (lo puede ejecutar cualquiera si nosotros no lo ejecutamos). Para ello hay una variable que indica el timestamp de la ultima vez, el cual permite que esta function se pueda volver a ejecutar tras 24 horas desde la ultima vez.

4. Al ejecutarse la función 'processUnstaking24Hours' verifica el timestamp y si es correcto, como ya restó todos los mUSDC de las cuentas, simplemente hace un unstaking con el proveedor por todo el USDC sumado en el mapping y se lo transfiere a los addresses del mapping, restando el costo de gas de la transacción dividido entre todos, el cual se lo queda el que ejecuta la función (se le devuelve el gas).

Nota 1: Como la función de 'processUnstaking24Hours' es permissionless para evitar problemas, durante la primer hora de las 24 horas solo la puede ejecutar un address whitelisteado por nosotros, de forma tal que nosotros somos los "encargados" y nos adjudica ese costo de gas, sino pasada esa hora la puede ejecutar cualquiera literalmente para evitar "que se tranque" su transacción.

Nota 2: La misma que en la función anterior.