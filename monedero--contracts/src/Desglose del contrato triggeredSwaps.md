# Contrato Inteligente: triggeredSwaps.sol

## Descripción General
Este contrato se encarga de gestionar pedidos de "inversión" a un precio bajo en un token determinado por parte de los usuarios del sistema. Las órdenes se ejecutan cuando se activan los triggers según la lógica establecida.

## Variables a Declarar

1. `mapping(uint256 => Order) public orders;`
   - Mapeo de orderId a la estructura Order.

2. `uint256 public nextOrderId;`
   - Contador para generar IDs únicos de órdenes.

3. `struct Order {`
   - `address userAddress;`
   - `uint256 mUSDC_a_invertir;`
   - `address tokenAddress_target;`
   - `uint256 targetPrice;`
   - `uint256 expirationTimestamp;`
   - `bool isActive;`
   `}`
   - Estructura para almacenar los detalles de cada orden.

4. `address public adminAddress;`
   - Dirección del administrador del contrato.

5. `uint256 public constant ORDER_FEE = 0.01 ether;`
   - Tarifa fija para crear una orden (equivalente a $0.01).

6. `IUniswapRouter public uniswapRouter;`
   - Interfaz para interactuar con Uniswap (asumiendo que se usa Uniswap para los swaps).

7. `IERC20 public mUSDC;`
   - Interfaz para interactuar con el token mUSDC.

## Características
- La mayoría de las funciones son permissionless, excepto crear y eliminar órdenes.
- No se devuelve gas en las funciones permissionless.
- El contrato tiene permiso para ejecutar operaciones en nombre de cualquier usuario.
- Se requiere un "watcher" externo para ejecutar las órdenes.

## Funciones

### 1. createTrigger
- **Permisos**: No permissionless
- **Costo**: $0.01
- **Parámetros**: userAddress, mUSDC_a_invertir, tokenAddress_target, targetPrice, expirationTimestamp
- **Proceso**:
  1. Verifica si userAddress tiene suficiente mUSDC (sin deducir).
  2. Guarda la información de la orden.

### 2. removeTrigger
- **Permisos**: No permissionless
- **Parámetros**: orderId
- **Proceso**: Elimina el pedido de inversión especificado.

### 3. triggerOrder
- **Permisos**: Permissionless
- **Parámetros**: Acepta múltiples orderId
- **Proceso**:
  1. Ejecuta el/los orderId si aplica(n).
  2. Si la ejecución es correcta, borra la entrada.
  3. Si no aplica, mantiene la entrada.
  4. Si el trigger es correcto pero el usuario no tiene saldo, borra la entrada.

### 4. flushTrigger
- **Permisos**: Permissionless
- **Proceso**:
  1. Ejecuta todas las órdenes que apliquen.
  2. Borra todas las órdenes con expirationTimestamp menor al timestamp actual.

### 5. removeExpired
- **Permisos**: Permissionless
- **Parámetros**: Opcionalmente, acepta múltiples orderId
- **Proceso**:
  - Sin parámetros: Borra todas las órdenes expiradas.
  - Con parámetros: Borra solo las orderId especificadas (si aplica).

## Notas Adicionales
- Al ejecutar una orden, se realiza el proceso de unstaking para el userAddress por el mUSDC_a_invertir y luego se ejecuta el SWAP correspondiente.
- Se podría implementar un sistema de notificaciones para órdenes no ejecutadas por falta de saldo (opcional).

------
------
------

# triggeredSwaps.sol SMART CONTRACT (raw text)

Este es el contrato que se encarga de recibir los pedidos de "inversion" a un precio bajo en un token determinado por parte de los usuarios del sistema, lo cual se ejecuta al activarse los triggers de acuerdo a la siguiente lógica. Todas las funciones de procesamiento son permissionless, pero no devuelven gas ni nada. Solo las primeras 2 no son permissionless ya que son de crear y eliminar ordenes. Se supone que las ejecutamos nosotros (que ya cobramos) pero si alguien se desespera que lo haga por su cuenta, por eso son permissionless.

Al "ejecutar una orden" se hace el proceso de unstaking para el userAddress por el mUSDC_a_invertir y luego se ejecuta el SWAP para lo que corresponde, este contrato tiene permiso de ejecutar para quien sea.

Nota: Nosotros tendremos un "watcher" para ejecutar.

---

## funcion 'createTrigger'

1. Un userAddress quiere crear un pedido de inversión, se le cobra $0.01 por hacerlo, se guarda (como sea): orderId, userAddress, mUSDC_a_invertir, tokenAddress_target, targetPrice, expirationTimestamp. La función verifica si userAddress tiene el mUSDC al momento solo para evitar mayores errores, pero no se lo deduce aún.

---

## function 'removeTrigger'

1. Un userAddress quiere eliminar un pedido de inversión, pasa el: orderId.

---

## function 'triggerOrder' (idealmente que acepte 'N' parametros)

1. Ejecuta el orderId (si aplica). Si la ejecución es correcta (el precio activa la orden) luego de ejecutada borra la entrada, por otro lado si no aplica simplemente deja la entrada (alguien ejecutó mal), pero finalmente si era correcto el trigger PERO el userAddress ya no tiene saldo, también borra la entrada (en este caso quizás podemos crear algo que marque una notifcación, pero no me parece tan importante).

---

## function 'flushTrigger'

1. Ejecuta todas las órdenes que apliquen, es permissionless, no devuelve gas ni nada. Además borra todas las órdenes que va encontrando con expirationTimestamp menor al current timestamp.

---

## function 'removeExpired' (idealmente que acepte 'N' parametros)

1. Si no recibe parámetros recorre y borra todas las órdenes con expirationTimestamp menor al current timestamp. Si recibe parámetros únicamente borra las orderId que les pasamos (si aplica).


en uniswap cpn white list de tokens con su pool