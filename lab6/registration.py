class RegistrationError(Exception):
    pass


class Student:
    def __init__(self, student_id):
        self.student_id = student_id
        self.total_hours = 0

    def register(self, code, hours):
        if self.total_hours + hours > 18:
            raise RegistrationError("credit-hour limit is 18")
        self.total_hours += hours
