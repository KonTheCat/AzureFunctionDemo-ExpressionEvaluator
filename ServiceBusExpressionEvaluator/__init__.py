import logging

import azure.functions as func


def main(msg: func.ServiceBusMessage, msgout: func.Out[str]):
    logging.info('Python ServiceBus queue trigger processed message: %s',
                 msg.get_body().decode('utf-8'))
    
    expression = msg.get_body().decode('utf-8')
    result = eval(expression)
    output = f'{expression} = {result}'
    logging.info(f'Write to output: {output}')
    msgout.set(output)