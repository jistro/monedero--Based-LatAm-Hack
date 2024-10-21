# Estructura de la aplicación Monedero

## 1. Narrativa
Monedero permite generar rendimientos fluidos con tus ahorros y remesas en Base, sin hacer absolutamente nada.

## 2. Operativa General
- Toda transacción tiene un costo de $0.01 USDC para quien la ejecuta, más el gas fee correspondiente.
- Las transacciones se realizan con USDC o mUSDC, descontando de allí los costos.
- El gas fee a veces lo paga la plataforma y otras veces se "presta" para cobrarlo después (como en el retiro diferido de hasta 24 horas).

## 3. Funciones de la DApp

### Visualización constante:
- Mostrar el saldo con el "Yield" generado (aunque no se haya cobrado).
- Calcular según el saldo en mUSDC y el Yield desde ese timestamp.
- Implementar una animación JavaScript que actualice el saldo segundo a segundo con 8 dígitos decimales.

### 3.1. Depositar USDC:
1. Recibir USDC
2. Mintear mUSDC (sintético)
3. Stakear para generar Yield

### 3.2. Depositar USDC vía otro Token:
1. Buscar el LP (posible whitelist para la demo) y ofrecer el swap
2. Recibir el USDC convertido desde TOKEN
3. Mintear mUSDC (sintético)
4. Stakear para generar Yield

### 3.3. Transferir y Pagar:
1. Solicitar un usuario de BASE o una dirección de wallet
2. Construir e iniciar la transacción del mUSDC

### 3.4. Retirar inmediatamente:
1. Devolver el mUSDC
2. Recibir USDC (con el Yield generado), pagando todo el gas

### 3.5. Retirar en máximo 24 horas:
1. Establecer un valor en un contrato para procesamiento en batch
2. Al ejecutar el batch:
   - Devolver el mUSDC
   - Recibir USDC (con el Yield generado)
   - Descontar el costo del gas dividido entre los procesados en el batch y los $0.01 de costo de transacción

### 3.6. Invertir con bajo riesgo:
1. Seleccionar un token de un whitelist (ETH, BUILD, BTC sintético, otros)
2. Seleccionar el precio sugerido (modificable hacia abajo)
3. Seleccionar el monto o porcentaje de la cuenta a invertir
4. Incluir el movimiento en una tabla para su ejecución
5. Mostrar una tabla para eliminar posiciones

## 4. Contratos

### Global Mint Hook (aplicable al ERC-20 del mUSDC):
- Se aplica cada vez que una cuenta cambia su balance de tokens
- Mintea el mUSDC faltante a la cuenta antes de realizar cualquier otra acción o descuento

Nota: Los hooks del ERC-20 manejan la aplicación de Yields al cambiar el balance.

# raw text
Claro, aquí tienes el texto convertido a Markdown:

# NARRATIVA

Monedero te permite generar rendimiento fluidos con tus ahorros y remesas en Base, sin hacer absolutamente nada!

# OPERATIVA GENERAL

Toda transacción tiene un costo de $0.01 USDC para quien la ejecuta, de fee, + el gas fe que corresponda. Como todo se hace con USDC o mUSDC se descuenta de ahí no como ETH.

El gas fee a veces lo pagan ellos y otras lo "prestamos" para después cobrarlo, como en el delayedWithdrawal (hasta 24 horas).

# FUNCIONES DAPP (no hacer diseño):

En todo momento se le muestra el saldo con el "Yield" generado (aunque no lo haya cobrado) calculado según su saldo en mUSDC y el Yield desde ese timestamp, con una animación javascript que cambia el saldo con 8 dígitos decimales (o los necesarios) para que aumente segundo a segundo (esto es puro front).

## 1º Deposit USDC:

1. Recibe USDC
2. Mintea mUSDC (sintético, no debe hacer nada más, pues el ERC-20 tiene los hoock para el tema de aplicar los Yields al momento de cambiar balance si aplica).
3. Stakea para empezar a generar Yield

## 2º Deposito USDC via otro Token (el que sea)

1. Busca el LP (podemos hacer un whitelist si queres para la demo) y ofrece el swap.
2. Recibe el USDC convertido desde TOKEN
3. Mintea mUSDC (sintético, no debe hacer nada más, pues el ERC-20 tiene los hoock para el tema de aplicar los Yields al momento de cambiar balance si aplica).
4. Stakea para empezar a generar Yield

## 3º Transferir y Pagar (esto lo pueden hacer directo desde su metamask si quisieran y aplica)

1. Pide un usuario de BASE o un wallet address.
2. Construye e inicia la transacción del mUSDC (no debe hacer nada más, pues el ERC-20 tiene los hoock para el tema de aplicar los Yields al momento de cambiar balance).

## 4º Retirar YA mismo

1. Regresa el mUSDC (sintético, no debe hacer nada más, pues el ERC-20 tiene los hoock para el tema de aplicar los Yields al momento de cambiar balance si aplica).
2. Recibe el USDC (con el Yield generado), paga todo el gas.

## 5º Retirar en Maximo 24 horas

1. Se pone un valor en un contrato que será procesado en batch más adelante.
2. Al ejecutarse el batch se regresa el mUSDC (sintético, no debe hacer nada más, pues el ERC-20 tiene los hoock para el tema de aplicar los Yields al momento de cambiar balance si aplica).
3. Recibe el USDC (con el Yield generado), descontando el costo del gas de la transacción general anterior dividido entre todos los que se procesaron en el batch y los $0.01 del costo de trasacción.

## 6º Invertir con bajo riesgo (se cobra $0.01 poner y sacar, ejecutar es automático).

1. Permite seleccionar un token a comprar de un whitelist: ETH, BUILD (solo para la demo), BTC (si hay algun sintético) y algún otro que recomiendes.
2. Selecciona el precio sugerido (puede modificarlo hacia abajo), se explica un texto de que es una inversion de bajo riesgo pero igual hay riesgo.
3. Selecciona el monto o % de su cuenta a invertir, si pone un monto le avisa que si su cuenta tiene menos de este monto no se ejecutará la orden.
4. Se incluye en una tabla el movimiento solicitado para ejecutarse.
5. Se mostrará una tabla para Eliminar posiciones también.

# CONTRATOS

En los que apliquen debe estar el "GLOBAL MINT HOOK", seguro en el ERC-20 del mUSDC

Global hook de remove/add balance (se aplica cada vez que una cuenta cambia su balance de tokens, para poner un nuevo punto de partida con su "total" de mUSDC generando el Yield):

1. Mintea el mUSDC que le falta a la cuenta y prosigue con lo que iba a hacer, antes de descontar nada.